# Originally Written by: Jonathan Johnson
# Updated by: Dustin Lee for Threat Code
# Additions and updates by Wes Lambert for Threat Code and VPC Mirroring

resource "aws_security_group" "threatcode" {
  name        = "threatcode_security_group"
  description = "ThreatCode: Security Group"
  vpc_id      = aws_vpc.terraform.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ip_whitelist
  }

  # Kibana Access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ip_whitelist
  }

  # private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.163.0/24"]
  }

  # Connect to Internet Gateway - internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Sniffing Group for Threat Code
resource "aws_security_group" "threatcode_sniffing" {
  name        = "threatcode_sniffing_security_group"
  description = "ThreatCode: Sniffing Security Group"
  vpc_id      = aws_vpc.terraform.id


  # private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.163.0/24"]
  }
}

resource "aws_network_interface" "threatcode" {
  count           = var.onions
  subnet_id       = aws_subnet.default.id
  private_ips     = ["172.16.163.2${count.index}"]
  security_groups = [aws_security_group.threatcode_sniffing.id]
}

data "aws_ami" "latest_so" {
  
  most_recent = true
  owners = ["679593333241"]

  filter {
    name = "name"
    values = ["Threat Code ${var.soversion}*"]
  }
}

resource "aws_instance" "threatcode" {
  depends_on = [ aws_internet_gateway.default ]
  count         = var.onions
  instance_type = var.instance_type
  ami           = data.aws_ami.latest_so.id != "" ? data.aws_ami.latest_so.id : var.ami

  tags = {
    Name = "security-onion-${count.index}"
  }

  subnet_id              = aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.threatcode.id]
  key_name               = aws_key_pair.auth.key_name
  private_ip             = "172.16.163.1${count.index}"

  root_block_device {
    delete_on_termination = true
    volume_size           = 250
  }
}

resource "aws_network_interface_attachment" "threatcode" {
  depends_on = [ aws_instance.threatcode ]
  count                = var.onions
  instance_id          = aws_instance.threatcode[count.index].id
  network_interface_id = aws_network_interface.threatcode[count.index].id
  device_index         = 1
}

resource "aws_ec2_traffic_mirror_target" "threat_code_sniffing" {
  count                = var.onions
  description          = "SO Sniffing Interface Target"
  network_interface_id = aws_network_interface.threatcode[count.index].id
  tags = {
    Name = "SO Mirror Target"
  }

  depends_on = [ aws_network_interface_attachment.threatcode ]
}

resource "aws_ec2_traffic_mirror_filter" "so_mirror_filter" {
  depends_on = [ aws_ec2_traffic_mirror_target.threat_code_sniffing  ]
  description = "Threat Code Mirror Filter - Allow All"
  tags = {
    Name = "SO Mirror Filter"
  }
}

resource "aws_ec2_traffic_mirror_filter_rule" "so_outbound" {
  depends_on = [ aws_ec2_traffic_mirror_filter.so_mirror_filter ]
  description = "SO Mirror Outbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.so_mirror_filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "egress"
}

resource "aws_ec2_traffic_mirror_filter_rule" "so_inbound" {
  depends_on = [ aws_ec2_traffic_mirror_filter.so_mirror_filter ]
  description = "SO Mirror Inbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.so_mirror_filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "ingress"
}
