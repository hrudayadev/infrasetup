provider "aws" {
 region = "${var.aws_region}"
 profile = "${var.aws_profile}"
}

#VPC 

resource "aws_vpc" "Indusface_Interview_VPC" {
  cidr_block = "172.16.0.0/16"
}

resource "aws_internet_gateway" "Indusface_Interview_Internet_Gateway" {
 vpc_id = "{aws_vpc.vpc.id}"
 tags {
      Name = "Indusface_Interview_Private_Subnet"
}
}


resource "aws_subnet" "Indusface_Interview_Public_Subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "172.16.0.0/24"
  map_public_ip_on_lunch = true
  availability_zone = "us-east-2c"
  tags {
      Name = "Indusface_Interview_Public_Subnet"
}
} 

resource "aws_subnet" "Indusface_Interview_Private_Subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "172.16.1.0/24"
  map_public_ip_on_lunch = false
  availability_zone = "us-east-2c"
  tags {
      Name = "Indusface_Interview_Private_Subnet"
}
}

resource "aws_eip" "elastis_eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.Indusface_Interview_Internet_Gateway"]
} 
 

resource "aws_nat_gateway" "Indusface_Interview_NAT_Gateway" {
    allocation_id = "${aws_eip.elastic_eip.id}"
    subnet_id = "${aws_subnet.Indusface_Interview_Public_Subnet.id}"
    depends_on = ["aws_internet_gateway.Indusface_Interview_Internet_Gateway"]
    tags {
      Name = "Indusface_Interview_NAT_Gateway"
}
}

resource "aws_route_table"  "Indusface_Interview_Public_Route_Table"  {
 vpc_id = "${aws_vpc.pvc.id}"
 route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internet_gateway.id}"
       }
 tags {
       Name = "Indusface_Interview_Public_Route_Table"
      }
}



resource "aws_default_route_table" "Indusface_Interview_Private_Route_Table"  {
 default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

 route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.Indusface_Interview_Public_Route_Table.id}"
       }
 tags {
       Name  = "Indusface_Interview_Private_Route_Table"
}
}

# Subnet Associations

resource "aws_route_table_association" "public_assoc" {
  subnet_id = "${aws_subnet.Indusface_Interview_Public_Subnet.id}"
  route_table_id = "${aws_route_table.Indusface_Interview_Public_Route_Table.id}"
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id = "${aws_subnet.Indusface_Interview_Private_Subnet.id}"
  route_table_id = "${aws_route_table.Indusface_Interview_Private_Route_Table.id}"
}


# Security Group 


resource "aws_security_group" "public" {
  name = "Indusface_Interview_Public_SG"
  description = "used for public and private instances for LB"
  vpc_id = "${aws_vpc.vpc.id}"
 
  ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_block = ["0.0.0.0/0"]
}
  ingress {
     from_port = 80
     to_port = 80
     protocol = "tcp"
     cidr_block = ["0.0.0.0/0"]
}

ingress {
     from_port = 443
     to_port = 443
     protocol = "tcp"
     cidr_block = ["0.0.0.0/0"]
}
  
}

resource "aws_security_group" "private" {
  name = "Indusface_Interview_Private_SG"
  description = "used private instances "
  vpc_id = "${aws_vpc.vpc.id}"
 
  ingress {
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_block = ["172.16.0.0/0"]
}
  ingress {
     from_port = 80
     to_port = 80
     protocol = "tcp"
     cidr_block = ["172.16.0.0/0"]
}

ingress {
     from_port = 443
     to_port = 443
     protocol = "tcp"
     cidr_block = ["172.16.0.0/0"]
}
}


# kep pair

resource "aws_key_pair" "auth" {
 key_name = "${var.key_name}"
 public_key = "${file(var.public_key_path)}"  
}


# server

resource "aws_eip" "instance_eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.Indusface_Interview_Internet_Gateway"]
} 


resource "aws_instance" "Indusface_Interview_Load_Balancer" {
  instance_type = "t2.micro"
  ami = "ami-5d055232"

root_block_device {
 volume_type = "gp2"
 volume_size = "20"
 delete_on_termination = "true"
}
  tags {
    Name = "Indusface_Interview_Load_Balancer"
  }

  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.public.id}"]
  subnet_id = "${aws_subnet.Indusface_Interview_Public_Subnet.id}"

}

resource "aws_instance" "Indusface_Interview_Web_Server" {
  instance_type = "t2.micro"
  ami = "ami-5d055232"
root_block_device {
 volume_type = "gp2"
 volume_size = "20"
 delete_on_termination = "true"
}
  tags {
    Name = "Indusface_Interview_Web_Server"
  }

  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.private.id}"]
  subnet_id = "${aws_subnet.Indusface_Interview_Private_Subnet.id}"

}



