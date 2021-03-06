terraform {
  required_version = ">= 1.1.5"
}

# Get the latest Windows 2019 image made by Amazon
data "aws_ami" "windows_2019" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a key pair to manage the servers
resource "aws_key_pair" "AzureDevOps" {
  key_name   = var.infra_env
  public_key = var.public_ssh_key
}

# Create network inferface for EC2 instance and assign secruity groups
resource "aws_network_interface" "vm_nic_1" {
  subnet_id   = var.subnet_id
  private_ips = ["10.0.0.100"]

  tags = {
    Name = "${var.infra_env}-nic-1"
  }

  security_groups = [
    var.rdp_id,
    var.winrm_id,
  ]
}

# Add elastic IP addresss for public connectivity
resource "aws_eip" "vm_eip_1" {
  vpc = true

  instance                  = aws_instance.virtualmachine_1.id
  associate_with_private_ip = "10.0.0.100"
  depends_on                = [var.gw_1]

  tags = {
    Name = "${var.infra_env}-eip-1"
  }

}

# Deploy new virtual machine using Windows 2019 latest ami
resource "aws_instance" "virtualmachine_1" {
  ami           = data.aws_ami.windows_2019.id
  instance_type = var.instance_type

  key_name = aws_key_pair.AzureDevOps.id

  #retrieve the Administrator password
  get_password_data = true

  connection {
    type     = "winrm"
    port     = 5986
    password = rsadecrypt(self.password_data, file("id_rsa"))
    https    = true
    insecure = true
    timeout  = "10m"
  }

  network_interface {
    network_interface_id = aws_network_interface.vm_nic_1.id
    device_index         = 0
  }

  user_data = file("./scripts/install-cwagent.ps1")

  tags = {
    Name = "${var.infra_env}-vm-1"
  }

}