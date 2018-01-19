provider "aws" {
 region = "${var.aws_region}"
 profile = "${var.aws_profile}"
}

#VPC 

resource "aws_vpc" "Indusface_Interview_VPC" {
  cidr_block = "172.16.0.0/16"
}

resource "aws_internet_gateway" "Indusface_Interview_Internet_Gateway" {
 vpc_id = "{aws_vpc.Indusface_Interview_VPC.id}"
 tags {
      Name = "Indusface_Interview_Internet_Gateway"
}
}




resource "aws_subnet" "Indusface_Interview_Public_Subnet" {
  vpc_id = "${aws_vpc.Indusface_Interview_VPC.id}"
  cidr_blcok = "172.16.0.0/24"
  map_public_ip_on_lunch = true
  availability_zone = "us-east-2c"
  tags {
      Name = "Indusface_Interview_Public_Subnet"
}
} 

resource "aws_subnet" "Indusface_Interview_Private_Subnet" {
  vpc_id = "${aws_vpc.Indusface_Interview_VPC.id}"
  cidr_blcok = "172.16.1.0/24"
  map_public_ip_on_lunch = false
  availability_zone = "us-east-2c"
  tags {
      Name = "Indusface_Interview_Private_Subnet"
}
}

resource "aws_eip" "elastic_eip" {
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
 vpc_id = "${aws_vpc.Indusface_Interview_VPC.id}"
 route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.Indusface_Interview_Internet_Gateway.id}"
       }
 tags {
       Name = "Indusface_Interview_Public_Route_Table"
      }
}



resource "aws_route_table" "Indusface_Interview_Private_Route_Table"  {
 vpc_id = "${aws_vpc.Indusface_Interview_VPC.id}"

 
 tags {
       Name  = "Indusface_Interview_Private_Route_Table"
}
}

resource "aws_route" "private_route" {
	route_table_id  = "${aws_route_table.Indusface_Interview_Private_Route_Table.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.Indusface_Interview_NAT_Gateway.id}"
}

# Subnet Associations

resource "aws_route_table_association" "Indusface_Interview_Public_Subnet" {
  subnet_id = "${aws_subnet.Indusface_Interview_Public_Subnet.id}"
  route_table_id = "${aws_route_table.Indusface_Interview_Public_Route_Table.id}"
}

resource "aws_route_table_association" "Indusface_Interview_Private_Subnet" {
  subnet_id = "${aws_subnet.Indusface_Interview_Private_Subnet.id}"
  route_table_id = "${aws_route_table.Indusface_Interview_Private_Route_Table.id}"
}


# Security Group 

resource "aws_network_acl" "Indusface_Interview_Public_SG" {
  vpc_id = "${aws_vpc.Indusface_Interview_VPC.id}"
  subnet_id = "${aws_subnet.Indusface_Interview_Public_Subnet.id}"

  ingress = {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }
  ingress {
    from_port   = 80
    to_port   = 80
    protocol  = "tcp"
	rule_no = 100
    cidr_blocks = ["0.0.0.0/0"]
  }ingress = {
    protocol = "tcp"
    rule_no = 102
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }
  
} 

resource "aws_network_acl" "Indusface_Interview_Private_SG" {
  vpc_id = "${aws_vpc.Indusface_Interview_VPC.id}"
  subnet_id = "${aws_subnet.Indusface_Interview_Private_Subnet.id}"

  ingress = {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block =  "172.16.0.0/0"
    from_port = 80
    to_port = 80
  }
  ingress {
    from_port   = 80
    to_port   = 80
    protocol  = "tcp"
	rule_no = 100
    cidr_blocks = "172.16.0.0/0"
  }
  ingress = {
    protocol = "tcp"
    rule_no = 102
    action = "allow"
    cidr_block =  "172.16.0.0/0"
    from_port = 443
    to_port = 443
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
  
  subnet_id = "${aws_subnet.Indusface_Interview_Private_Subnet.id}"

}



