provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "factorio" {
  bucket_prefix = "factorio-"
  versioning {
    enabled = true
  }
}

resource "aws_ecs_cluster" "factorio" {
  name = "factorio-ecs-cluster"
}

data "template_file" "factorio" {
  template = "${file("${path.module}/tasks/factorio.json")}"

  vars {
    image   = "rangerscience/factorio:fargate"
    storage = "s3://${aws_s3_bucket.factorio.id}"
    autosave_rate = 300 # Seconds between saves to S3
  }
}

resource "aws_ecs_task_definition" "factorio" {
  family                   = "factorio"
  container_definitions    = "${data.template_file.factorio.rendered}"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  requires_compatibilities = ["FARGATE"]
  cpu                      = "4096" // 4 vCPU
  memory                   = "8192" // 8 GB (min for 4 vCPU)

  task_role_arn            = "${aws_iam_role.factorio.arn}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "factorio" {
  cidr_block = "10.0.1.0/26"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_ecs_service" "factorio" {
  name            = "factorio"
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.factorio.id}"
  task_definition = "${aws_ecs_task_definition.factorio.arn}"
  desired_count   = 1

  network_configuration {
    subnets = ["${aws_subnet.factorio.id}"]
    assign_public_ip = true
  }
}

resource "aws_iam_role" "factorio" {
  name = "factorio"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "factorio" {
  statement {
    sid = "1"
    actions = ["*"]
    resources = ["${aws_s3_bucket.factorio.arn}"]
  }
}

resource "aws_iam_policy" "factorio" {
  policy = "${data.aws_iam_policy_document.factorio.json}"
}

resource "aws_iam_role_policy_attachment" "factorio" {
  role = "${aws_iam_role.factorio.name}"
  policy_arn = "${aws_iam_policy.factorio.arn}"
}
