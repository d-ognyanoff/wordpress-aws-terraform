provider "aws" {
  region = "eu-west-1"
}


module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}

resource "aws_instance" "wp0" {
  ami = "ami-09ce2fc392a4c0fbc"
  instance_type = "t2.micro"
  subnet_id      = aws_subnet.eu-west-1a.id
  key_name = var.ssh_key.keyname
  associate_public_ip_address = true
  user_data = file("./installwp.sh")
  vpc_security_group_ids = [aws_security_group.SG_for_EC2.id]
  tags = {
      Name = "Wordpress-0"
  }
}

resource "aws_instance" "wp1" {
  ami = "ami-09ce2fc392a4c0fbc"
  instance_type = "t2.micro"
  subnet_id      = aws_subnet.eu-west-1b.id
  key_name = var.ssh_key.keyname
  associate_public_ip_address = true
  user_data = file("./installwp.sh")
  vpc_security_group_ids = [aws_security_group.SG_for_EC2.id]
  tags = {
      Name = "Wordpress-1"
  }
}



resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

resource "aws_subnet" "eu-west-1a" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "eu-west-1a"
  }
}

resource "aws_subnet" "eu-west-1b" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "eu-west-1b"
  }
}

resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "MyIG"
  }
  depends_on = [aws_vpc.myvpc]
}

resource "aws_route" "route_to_ig" {
  route_table_id         = aws_vpc.myvpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mygw.id
  depends_on             = [aws_internet_gateway.mygw, aws_vpc.myvpc]
}

resource "aws_route_table_association" "eu-west-1a" {
  subnet_id      = aws_subnet.eu-west-1a.id
  route_table_id = aws_vpc.myvpc.main_route_table_id
}

resource "aws_route_table_association" "eu-west-1b" {
  subnet_id      = aws_subnet.eu-west-1b.id
  route_table_id = aws_vpc.myvpc.main_route_table_id
}

resource "aws_efs_file_system" "myefs" {
  encrypted = true
  tags = {
    Name = "MyEFS"
  }
}

resource "aws_efs_mount_target" "eu-west-1a" {
  file_system_id  = aws_efs_file_system.myefs.id
  subnet_id       = aws_subnet.eu-west-1a.id
  security_groups = [aws_security_group.SG_for_EFS.id]
  depends_on      = [aws_efs_file_system.myefs, aws_security_group.SG_for_EFS]
}

resource "aws_efs_mount_target" "eu-west-1b" {
  file_system_id  = aws_efs_file_system.myefs.id
  subnet_id       = aws_subnet.eu-west-1b.id
  security_groups = [aws_security_group.SG_for_EFS.id]
  depends_on      = [aws_efs_file_system.myefs, aws_security_group.SG_for_EFS]
}

resource "aws_security_group" "SG_for_EC2" {
  name        = "SG_for_EC2"
  description = "Allow 80, 443, 22 port inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "TLS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${module.myip.address}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "SG_for_RDS" {
  name        = "SG_for_RDS"
  description = "Allow MySQL inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description     = "RDS from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.SG_for_EC2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [aws_security_group.SG_for_EC2]
}

resource "aws_security_group" "SG_for_EFS" {
  name        = "SG_for_EFS"
  description = "Allow NFS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description     = "NFS from EC2"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.SG_for_EC2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [aws_security_group.SG_for_EC2]
}

resource "aws_security_group" "SG_for_ELB" {
  name        = "SG_for_ELB"
  description = "Allow traffic for ELB"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "Allow all inbound traffic on the 80 port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.SG_for_EC2.id]
  }
  depends_on = [aws_security_group.SG_for_EC2]
}

resource "aws_db_subnet_group" "default" {
  name       = "main1"
  subnet_ids = [aws_subnet.eu-west-1a.id, aws_subnet.eu-west-1b.id]
}

resource "aws_db_instance" "mysql" {
  identifier = "mysql"
  engine     = "mysql"
  engine_version                  = "5.7.33"
  instance_class                  = "db.t2.micro"
  db_subnet_group_name            = aws_db_subnet_group.default.name
  enabled_cloudwatch_logs_exports = ["general", "error"]
  name                            = var.rds_credentials.dbname
  username                        = var.rds_credentials.username
  password                        = var.rds_credentials.password
  allocated_storage               = 20
  max_allocated_storage           = 0
  backup_retention_period         = 7
  backup_window                   = "00:00-00:30"
  maintenance_window              = "Sun:21:00-Sun:21:30"
  storage_type                    = "gp2"
  vpc_security_group_ids          = [aws_security_group.SG_for_RDS.id]
  skip_final_snapshot             = true
  depends_on                      = [aws_security_group.SG_for_RDS, aws_db_subnet_group.default]
}

resource "aws_elb" "my_elb" {
  name            = "My-ELB"
  instances = [aws_instance.wp0.id, aws_instance.wp1.id]
  security_groups = [aws_security_group.SG_for_ELB.id]
  subnets         = [aws_subnet.eu-west-1a.id, aws_subnet.eu-west-1b.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:80"
    interval            = 20
  }

  cross_zone_load_balancing = true
  idle_timeout              = 60
  depends_on                = [aws_security_group.SG_for_ELB]
}


resource "local_file" "wp_config" {
  filename = "../ansible/roles/wordpress/files/wp-config.php"
  content = templatefile("./wp-config.tmpl", {
    database_name = var.rds_credentials.dbname
    username      = var.rds_credentials.username
    password      = var.rds_credentials.password
    db_host       = aws_db_instance.mysql.endpoint
  })
  depends_on = [aws_db_instance.mysql]
}

resource "local_file" "servers" {
  filename = "../ansible/hosts"
  file_permission = "0666"
  content = templatefile("./servers.tmpl", {
    ip = aws_instance.wp0.public_ip
  })
  depends_on = [aws_instance.wp0, aws_instance.wp1] 
}


resource "null_resource" "ansible" {
  provisioner "local-exec" {
    working_dir = "../ansible"
    command     = "ansible-playbook -i hosts wp.yml"
  }
  depends_on = [local_file.servers, local_file.wp_config, aws_instance.wp0, aws_instance.wp1]
}


output "elb_dns" {
  value = aws_elb.my_elb.dns_name
}