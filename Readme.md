Factorio Estado de construcción Estado del actualizador Versión de Docker Docker Pulls Estrellas Docker Capas Microbadger
1.1.19, 1.1, latest (1,1 / Dockerfile)
1.0.0, 1.0, stable (1,0 / Dockerfile)
0.18.47, 0.18 (0.18 / Dockerfile)
0.17.79, 0.17 (0.17 / Dockerfile)
0.16.51, 0.16 (0.16 / Dockerfile)
0.15.40, 0.15 (0.15 / Dockerfile)
0.14.23, 0.14 (0.14 / Dockerfile)
Descripciones de etiquetas
latest - versión más actualizada (puede ser experimental).
stable- versión declarada estable en factorio.com .
0.x - última versión en una sucursal.
0.x.y - una versión específica.
0.x-z - corrección incremental para esa versión.
¿Qué es Factorio?
Factorio es un juego en el que construyes y mantienes fábricas.

Estarás extrayendo recursos, investigando tecnologías, construyendo infraestructura, automatizando la producción y luchando contra enemigos. Usa tu imaginación para diseñar tu fábrica, combina elementos simples en estructuras ingeniosas, aplica habilidades de gestión para que siga funcionando y finalmente protégela de las criaturas a las que realmente no les agradas.

El juego es muy estable y optimizado para construir fábricas masivas. Puedes crear tus propios mapas, escribir mods en Lua o jugar con amigos a través del multijugador.

NOTA: Este es solo el servidor. El juego completo está disponible en Factorio.com , Steam , GOG.com y Humble Bundle .

Uso
Inicio rápido
Ejecute el servidor para crear la estructura de carpetas y los archivos de configuración necesarios. Para este ejemplo, los datos se almacenan en formato /opt/factorio.

sudo mkdir -p / opt / factorio
sudo chown 845: 845 / opt / factorio
sudo docker ejecutar -d \
  -p 34197: 34197 / udp \
  -p 27015: 27015 / tcp \
  -v / opt / factorio: / factorio \
  --nombre factorio \
  --restart = siempre \
  factoriotools / factorio
Para aquellos que son nuevos en Docker, aquí hay una explicación de las opciones:

-d - Ejecutar como un demonio ("separado").
-p - Exponer puertos.
-v- Monte /opt/factorioen el sistema de archivos local /factorioen el contenedor.
--restart - Reinicie el servidor si falla y al iniciar el sistema
--name - Nombra el contenedor "factorio" (de lo contrario, tiene un nombre aleatorio divertido).
El chowncomando es necesario porque en 0.16+, ya no ejecutamos el servidor del juego como root por razones de seguridad, sino como un usuario 'factorio' con ID de usuario 845. Por lo tanto, el host debe permitir que ese usuario escriba estos archivos.

Verifique los registros para ver qué sucedió:

Docker logs factorio
Detenga el servidor:

factorio de la parada del acoplador
Ahora hay un server-settings.jsonarchivo en la carpeta /opt/factorio/config. Modifique esto a su gusto y reinicie el servidor:

factorio de inicio de docker
Intente conectarse al servidor. Verifique los registros si no funciona.

Consola
Para emitir comandos de consola al servidor, inicie el servidor en modo interactivo con -it. Abra la consola con docker attachy luego escriba comandos.

docker run -d -it \
      --nombre factorio \
      factoriotools / factorio
Docker adjuntar factorio
Actualización
Antes de actualizar, haga una copia de seguridad del archivo save. Es fácil guardar en el cliente.

Asegúrese de que -vse usó para ejecutar el servidor de modo que el guardado esté fuera del contenedor de Docker. El docker rmcomando destruye completamente el contenedor, que incluye el guardado si no está almacenado en un volumen de datos.

Elimina el contenedor y actualiza la imagen:

factorio de la parada del acoplador
docker rm factorio
Docker pull factoriotools / factorio
Ahora ejecute el servidor como antes. En aproximadamente un minuto, la nueva versión de Factorio debería estar en funcionamiento, completa con guardados y configuración.

Ahorra
Se _autosave1.zipgenera un nuevo mapa con nombre la primera vez que se inicia el servidor. Los archivos map-gen-settings.jsony se utilizan para la configuración del mapa. En ejecuciones posteriores se utiliza el guardado más reciente.map-settings.json/opt/factorio/config

Para cargar un guardado antiguo, detenga el servidor y ejecute el comando touch oldsave.zip. Esto restablece la fecha. Luego reinicie el servidor. Otra opción es eliminar todos los archivos guardados excepto uno.

Para generar un nuevo mapa, detenga el servidor, elimine todos los datos guardados y reinicie el servidor.

Especificar un guardado directamente (0.17.79-2 +)
Puede especificar un guardado específico para cargar configurando el servidor a través de un conjunto de variables de entorno:

Para cargar un conjunto de guardado existente SAVE_NAMEcon el nombre de su archivo de guardado existente ubicado dentro del savesdirectorio, sin la .zipextensión:

sudo docker ejecutar -d \
  -p 34197: 34197 / udp \
  -p 27015: 27015 / tcp \
  -v / opt / factorio: / factorio \
  -e LOAD_LATEST_SAVE = falso \
  -e SAVE_NAME = reemplazarme \
  --nombre factorio \
  --restart = siempre \
  factoriotools / factorio
Para generar un nuevo conjunto de mapas GENERATE_NEW_SAVE=truey especificar SAVE_NAME:

sudo docker ejecutar -d \
  -p 34197: 34197 / udp \
  -p 27015: 27015 / tcp \
  -v / opt / factorio: / factorio \
  -e LOAD_LATEST_SAVE = falso \
  -e GENERATE_NEW_SAVE = verdadero \
  -e SAVE_NAME = reemplazarme \
  --nombre factorio \
  --restart = siempre \
  factoriotools / factorio
Mods
Copie los mods en la carpeta de mods y reinicie el servidor.

A partir de 0.17, se agregó una nueva variable de entorno UPDATE_MODS_ON_STARTque, si se establece en, truehará que los mods se actualicen al iniciar el servidor. Si se establece un nombre de usuario y un token de Factorio válidos, se deben proporcionar o, de lo contrario, el servidor no se iniciará. Pueden configurarse como secretos de la ventana acoplable, variables de entorno o extraerse del archivo server-settings.json.

Escenarios
Si desea iniciar un escenario desde un comienzo limpio (no desde un mapa guardado), deberá iniciar la imagen de la ventana acoplable desde un punto de entrada alternativo. Para hacer esto, use el archivo entrypoint de ejemplo almacenado en el directorio / factorio / entrypoints en el volumen, y ejecute la imagen con la siguiente sintaxis. Tenga en cuenta que esta es la sintaxis normal con la adición de la configuración --entrypoint Y el argumento adicional al final, que es el nombre del escenario en la carpeta Escenarios.

Docker ejecutar -d \
  -p 34197: 34197 / udp \
  -p 27015: 27015 / tcp \
  -v / opt / factorio: / factorio \
  --nombre factorio \
  --restart = siempre \
  --punto de entrada " /scenario.sh " \
  factoriotools / factorio \
  MyScenarioName
Conversión de escenarios en mapas normales
Si desea exportar su escenario a un mapa guardado, puede usar el punto de entrada de ejemplo similar al uso del escenario anterior. Factorio se ejecutará una vez, convirtiendo el escenario en un mapa guardado en su directorio de guardado. Un reinicio de la imagen de la ventana acoplable utilizando las opciones estándar cargará ese mapa, como si el escenario se hubiera iniciado con el ejemplo de Escenarios mencionado anteriormente.

Docker ejecutar -d \
  -p 34197: 34197 / udp \
  -p 27015: 27015 / tcp \
  -v / opt / factorio: / factorio \
  --nombre factorio \
  --restart = siempre \
  --punto de entrada " /scenario2map.sh " \
  factoriotools / factorio
  MyScenarioName
RCON
Establezca la contraseña de RCON en el rconpwarchivo. Se genera una contraseña aleatoria si rconpwno existe.

Para cambiar la contraseña, detenga el servidor, modifique rconpwy reinicie el servidor.

Para "deshabilitar" RCON no exponga el puerto 27015, es decir, inicie el servidor sin -p 27015:27015/tcp. RCON todavía se está ejecutando, pero nadie puede conectarse a él.

Lista blanca (0.15.3+)
Cree el archivo config/server-whitelist.jsony agregue los usuarios incluidos en la lista blanca.

[
 " tú " ,
 " amigo " 
]
Banlisting (0.17.1+)
Cree un archivo config/server-banlist.jsony agregue los usuarios excluidos.

[
     " bad_person " ,
     " otra_bad_person " 
]
Listado administrativo (0.17.1+)
Cree el archivo config/server-adminlist.jsony agregue los usuarios administrados.

[
   " tú " ,
   " amigo " 
]
Personalizar archivos de configuración (0.17.x +)
De fábrica, factorio no admite variables de entorno dentro de los archivos de configuración. Una solución alternativa es envsubstcuyo uso genera los archivos de configuración dinámicamente durante el inicio a partir de las variables de entorno establecidas en docker-compose:

Ejemplo que reemplaza server-settings.json:

factorio_1 :
   imagen : factoriotools / 
  puertos factorio :
    - " 34197: 34197 / UDP "
   volúmenes :
   - / opt / factorio: / factorio 
   - ./server-settings.json:/server-settings.json 
  entorno :
    - INSTANCE_NAME = Nombre de su instancia 
    - INSTANCE_DESC = 
  Punto de entrada de la descripción de su instancia : / bin / sh -c "mkdir -p / factorio / config && envsubst </server-settings.json> /factorio/config/server-settings.json && exec /docker-entrypoint.sh "
El server-settings.jsonarchivo puede contener las referencias de variables como esta:

" nombre " : " $ {INSTANCE_NAME} " ,
 " descripción " : " $ {INSTANCE_DESC} " ,
Detalles del contenedor
La filosofía es mantenerlo simple .

El servidor debería iniciarse a sí mismo.
Prefiere los archivos de configuración a las variables de entorno.
Utilice un volumen para los datos.
Volúmenes
Para simplificar las cosas, el contenedor utiliza un solo volumen montado en /factorio. Este volumen almacena configuraciones, modificaciones y guardados.

Los archivos de este volumen deben ser propiedad del usuario de factorio, uid 845.

  factorio
  |-- config
  |   |-- map-gen-settings.json
  |   |-- map-settings.json
  |   |-- rconpw
  |   |-- server-adminlist.json
  |   |-- server-banlist.json
  |   |-- server-settings.json
  |   `-- server-whitelist.json
  |-- mods
  |   `-- fancymod.zip
  `-- saves
      `-- _autosave1.zip
Docker Compose
Docker Compose es una forma sencilla de ejecutar contenedores de Docker.

Primero obtenga un archivo docker-compose.yml . Para obtenerlo de este repositorio:

clon de git https://github.com/factoriotools/factorio-docker.git
 cd docker_factorio_server / 0.17
O haz el tuyo propio:

versión: ' 2 '
servicios:
  factorio:
    imagen: factoriotools / factorio
    puertos:
     - " 34197: 34197 / udp " 
     - " 27015: 27015 / tcp "
    volúmenes:
     - / opt / factorio: / factorio
Ahora vaya al directorio con docker-compose.yml y ejecute:

sudo mkdir -p / opt / factorio
sudo chown 845: 845 / opt / factorio
sudo docker-compose up -d
Puertos
34197/udp- Servidor de juegos (requerido). Esto se puede cambiar con la PORTvariable de entorno.
27015/tcp - RCON (opcional).
Juegos LAN
Asegúrese de que la lanconfiguración en server-settings.json sea true.

  " visibilidad " :
  {
    " public " : falso,
     " lan " : verdadero 
  },
Inicie el contenedor con la --network=hostopción para que los clientes puedan encontrar automáticamente juegos de LAN. Consulte el Inicio rápido para crear el /opt/factoriodirectorio.

sudo docker ejecutar -d \
  --network = host \
  -p 34197: 34197 / udp \
  -p 27015: 27015 / tcp \
  -v / opt / factorio: / factorio \
  --nombre factorio \
  --restart = siempre \
  factoriotools / factorio
Implementar en otras plataformas
Vagabundo
Vagrant es una forma fácil de configurar una máquina virtual (VM) para ejecutar Docker. El repositorio de la caja de Factorio Vagrant contiene un Vagrantfile de muestra.

Para los juegos de LAN, la VM necesita una IP interna para que los clientes se conecten. Una forma de hacer esto es con una red pública. La máquina virtual usa DHCP para adquirir una dirección IP. La VM también debe reenviar el puerto 34197.

  config . vm . configuración de red  "red_pública" 
  . vm . red " puerto_enviado " , invitado : 34197 , host : 34197   
Implementación de Amazon Web Services (AWS)
Si está buscando una forma sencilla de implementar esto en Amazon Web Services Cloud, consulte el repositorio Factorio Server Deployment (CloudFormation) . Este repositorio contiene una plantilla de CloudFormation que lo pondrá en funcionamiento en AWS en cuestión de minutos. Opcionalmente, utiliza precios al contado, por lo que el servidor es muy barato y puede apagarlo fácilmente cuando no esté en uso.

Solución de problemas
Mi servidor aparece en el navegador del servidor, pero nadie puede conectarse
Revise los registros. Si existe la línea Own address is RIGHT IP:WRONG PORT, esto podría deberse al proxy de Docker. Si la IP y el puerto son correctos, probablemente se deba a un problema de reenvío de puertos o firewall.

De forma predeterminada, Docker enruta el tráfico a través de un proxy. El proxy cambia el puerto UDP de origen, por lo que se detecta el puerto incorrecto. Consulte la publicación del foro Puerto incorrecto detectado para el servidor alojado en Docker para obtener más detalles.

Para corregir el puerto incorrecto, inicie el servicio Docker con el --userland-proxy=falseconmutador. Docker enrutará el tráfico con reglas de iptables en lugar de un proxy. Agregue el conmutador a la DOCKER_OPTSvariable de entorno o ExecStarten la definición del servicio systemd de Docker. Los detalles varían según el sistema operativo.

Cuando ejecuto un servidor en un puerto además del 34197, nadie puede conectarse desde el navegador del servidor
Utilice la PORTvariable de entorno para iniciar el servidor en un puerto diferente, .eg docker run -e "PORT=34198". Esto cambia el puerto de origen en los paquetes utilizados para la detección de puertos. -p 34198:34197funciona bien para servidores privados, pero el navegador del servidor detecta el puerto incorrecto.

Colaboradores
dtandersen - Mantenedor
Fank - Programador del perro guardián de Factorio que mantiene la versión actualizada.
SuperSandro2000 - CI Guy, Mantenedor y corredor del perro guardián Factorio. Contribuyó con actualizaciones de versión y escribió los scripts de Travis.
DBendit : lista de administradores codificada, compatibilidad con listas de prohibición y actualizaciones de versiones aportadas
Zopanix - Autor original
Rfvgyhn - Contraseña RCON codificada generada aleatoriamente
gnomus : compatibilidad con listas de wite codificadas
bplein : compatibilidad con escenarios codificados
jaredledvina - Actualizaciones de versión contribuidas
carlbennett : actualización de versiones y corrección de errores
