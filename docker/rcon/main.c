#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#include <netdb.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <arpa/inet.h>

#define MIN_PACKET 10
#define MAX_PACKET 4096
#define MAX_BODY (MAX_PACKET - (3 * sizeof(uint32_t)) - 2)

#define RCON_HOST "127.0.0.1"

typedef enum {
    RCON_TYPE_RESPONSE = 0,
    RCON_TYPE_EXECCOMMAND = 2,
    RCON_TYPE_AUTH_RESPONSE = 2,
    RCON_TYPE_AUTH = 3,
} packet_type;

typedef struct {
    uint32_t length;
    uint32_t id;
    packet_type type;
    char body[MAX_BODY];
} packet;

int rcon_open(const char *port);
void rcon_create(packet* pkt, packet_type type, const char* body);
bool rcon_send(int rcon_socket, const packet* pkt);
bool rcon_auth(int rcon_socket, const char* password);
bool rcon_recv(int rcon_socket, packet* pkt, packet_type expected_type);
char* combine_args(int argc, char* argv[]);
char* read_password(const char* conf_dir);

int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr, "error: missing command argument\n");
        return EXIT_FAILURE;
    }
    
    srand((unsigned int)time(NULL));
    
    const char* port = getenv("RCON_PORT");
    if (port == NULL) {
        fprintf(stderr, "error: missing $RCON_PORT env\n");
        return EXIT_FAILURE;
    }
    
    const char* conf_dir = getenv("CONFIG");
    if (conf_dir == NULL) {
        fprintf(stderr, "error: missing $CONFIG env");
        exit(EXIT_FAILURE);
    }
    
    int rcon_socket = rcon_open(port);
    if (rcon_socket == -1) {
        fprintf(stderr, "error: could not connect\n");
        return EXIT_FAILURE;
    }
    
    if (!rcon_auth(rcon_socket, read_password(conf_dir))) {
        fprintf(stderr, "error: login failed\n");
        return EXIT_FAILURE;
    }
    
    packet pkt;
    rcon_create(&pkt, RCON_TYPE_EXECCOMMAND, combine_args(argc, argv));
    if (!rcon_send(rcon_socket, &pkt)) {
        fprintf(stderr, "error: send command failed\n");
        return EXIT_FAILURE;
    }
    
    if (rcon_recv(rcon_socket, &pkt, RCON_TYPE_RESPONSE) && pkt.length > 0) {
        puts(pkt.body);
    }
    
    return EXIT_SUCCESS;
}

char* combine_args(int argc, char* argv[]) {
    // combine all cli arguments
    char* command = malloc(MAX_BODY);
    memset(command, 0, MAX_BODY);
    strcat(command, argv[1]);
    
    for (int idx = 2; idx < argc; idx++) {
        strcat(command, " ");
        strcat(command, argv[idx]);
    }
    
    return command;
}

char* read_password(const char* conf_dir) {
    char* path = malloc(strlen(conf_dir) + 64);
    strcpy(path, conf_dir);
    strcat(path, "/rconpw");
    
    FILE* fptr = fopen(path, "r");
    fseek(fptr, 0, SEEK_END);
    long fsize = ftell(fptr);
    fseek(fptr, 0, SEEK_SET);  /* same as rewind(f); */

    char *password = malloc(fsize + 1);
    size_t bytes_read = fread(password, fsize, 1, fptr);
    (void)bytes_read; // Suppress unused warning
    fclose(fptr);

    password[fsize] = 0;
    if (password[fsize-1] == '\n') {
        password[fsize-1] = 0;
    }
    
    return password;
}

int rcon_open(const char *port) {
    struct sockaddr_in address = {
        .sin_family = AF_INET,
        .sin_port = htons(atoi(port))
    };
    inet_aton(RCON_HOST, &address.sin_addr);
    
    int rcon_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (connect(rcon_socket, (struct sockaddr*) &address, sizeof(address)) < 0) {
        return -1;
    } else {
        return rcon_socket;
    }
}

void rcon_create(packet* pkt, packet_type type, const char* body) {
    size_t body_length = strlen(body);
    if (body_length >= MAX_BODY - 2) {
        fprintf(stderr, "error: command to long");
        exit(EXIT_FAILURE);
    }
    
    pkt->id = abs(rand());
    pkt->type = type;
    pkt->length = (uint32_t)(sizeof(pkt->id) + sizeof(pkt->type) + body_length + 2);
    
    memset(pkt->body, 0, MAX_BODY);
    strncpy(pkt->body, body, MAX_BODY);
}

bool rcon_recv(int rcon_socket, packet* pkt, packet_type expected_type) {
    memset(pkt, 0, sizeof(*pkt));
    
    // Read response packet length
    ssize_t expected_length_bytes = sizeof(pkt->length);
    ssize_t rx_bytes = recv(rcon_socket, &(pkt->length), expected_length_bytes, 0);
    
    if (rx_bytes == -1) {
        perror("error: socket error");
        return false;
    } else if (rx_bytes == 0) {
        fprintf(stderr, "error: no data recieved\n");
        return false;
    } else if (rx_bytes < expected_length_bytes || pkt->length < MIN_PACKET || pkt->length > MAX_PACKET) {
        fprintf(stderr, "error: invalid data\n");
        return false;
    }
    
    ssize_t received = 0;
    while (received < pkt->length) {
        rx_bytes = recv(rcon_socket, (char *)pkt + sizeof(pkt->length) + received, pkt->length - received, 0);
        if (rx_bytes < 0) {
            perror("error: socket error");
            return false;
        } else if (rx_bytes == 0) {
            fprintf(stderr, "error: connection lost\n");
            return false;
        }
        
        received += rx_bytes;
    }
    
    return pkt->type == expected_type;
}

bool rcon_send(int rcon_socket, const packet* pkt) {
    size_t length = sizeof(pkt->length) + pkt->length;
    char *ptr = (char*) pkt;
    
    while (length > 0) {
        ssize_t ret = send(rcon_socket, ptr, length, 0);
        
        if (ret == -1) {
            return false;
        }
        
        ptr += ret;
        length -= ret;
    }
    
    return true;
}

bool rcon_auth(int rcon_socket, const char* password) {
    packet pkt;
    rcon_create(&pkt, RCON_TYPE_AUTH, password);
    
    if (!rcon_send(rcon_socket, &pkt)) {
        return false;
    }
    
    if (!rcon_recv(rcon_socket, &pkt, RCON_TYPE_AUTH_RESPONSE)) {
        return false;
    }
    
    return true;
}
