provider "aws" {
 region = "${var.aws_region}"
 profile = "${var.aws_profile}"
}

#VPC 

resource "aws_vpc" "vpc" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_internet_gateway" "internet_gateway" {
 vpc_id = "{aws_vpc.vpc.id}"
}

resource "aws_route_table" "public"  {
 vpc_id = "${aws_vpc.pvc.id}"
 route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internet_gateway.id}"
       }
 tags {
       Name = "public"
      }
}

resource "aws_default_route_table" "private"  {
 default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
 tags {
       Name  = "private"
}
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "10.1.1.0/24"
  map_public_ip_on_lunch = true
  availability_zone = "ap-south-1b"
  tags {
      Name = "public"
}
} 

resource "aws_subnet" "private1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "10.1.2.0/24"
  map_public_ip_on_lunch = false
  availability_zone = "ap-south-1a"
  tags {
      Name = "private1"
}
} 

resource "aws_subnet" "private2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "10.1.3.0/24"
  map_public_ip_on_lunch = false
  availability_zone = "ap-south-1a"
  tags {
      Name = "private2"
}
} 


resource "aws_subnet" "rds1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "10.1.4.0/24"
  map_public_ip_on_lunch = false
  availability_zone = "ap-south-1a"
  tags {
      Name = "rds1"
}
}
 
resource "aws_subnet" "rds2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "10.1.5.0/24"
  map_public_ip_on_lunch = false
  availability_zone = "ap-south-1b"
  tags {
      Name = "rds2"
}
}
 
resource "aws_subnet" "rds3" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_blcok = "10.1.6.0/24"
  map_public_ip_on_lunch = false
  availability_zone = "ap-south-1b"
  tags {
      Name = "rds3"
}
} 


# subnet associations

resource "aws_route_table_association" "public_assoc" {
 subnet_id = "${aws_subnet.public.id}"
 route_table_id = "${aws_route_table.public.id}"

}

resource "aws_route_table_association" "private1_assoc" {
 subnet_id = "${aws_subnet.private1.id}"
 route_table_id = "${aws_route_table.public.id}"

}


resource "aws_route_table_association" "private2_assoc" {
 subnet_id = "${aws_subnet.private2.id}"
 route_table_id = "${aws_route_table.public.id}"

}

resource "aws_db_subnet_greoup" "rds_subnetgreoup" {
  name = "rds_subnetgroup"
  subnet_ids = ["${aws_subnet.rds1.id}", "${aws_subnet.rds2.id}", "${aws_subnet.rds3.id}" ]
  tags {
       Name = "rds_sng"
   }
}


# Security Group 


resource "aws_security_group" "public" {
  name = "sg_public"
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
  egress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_block = ["0.0.0.0/0"]
}
}

resource "aws_security_group" "private" {
  name = "sg_private"
  description = "used private instances "
  vpc_id = "${aws_vpc.vpc.id}"
 
  ingress {
     from_port = 0
     to_port = 0
     protocol = "-1"
     cidr_block = ["0.0.0.0/0"]
}
  egress {
     from_port = 0
     to_port = 0
     protocol = "tcp"
   cidr_block = ["0.0.0.0/0"]
}

}

#RDS Security group 

resource "aws_security_group" "RDS" {
  name = "sg_rds"
  description = "for DB insta"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
   from_port = 3306
   to_port = 3306
   protocol = "tcp"
   security_groups = ["${aws_security_group.public.id}", "${aws_security_group.private.id}"]
 }

}


#DB

resource "aws_db_instance" "db" {
 allocated_storage = 10
 engine          = "mysql"
 engine_version = "5.6.27"
 instance_class = "${var.db_instance_class}"
 name            = "${var.dbname}"
 username = "${var.dbuser}"
 password = "${var.dbpassword}"
 db_subnet_greoup_name = "${aws_db_subnet_group.rds_subnetgreoup.name}"
 vpc_security_group_ids = ["${aws_security_group.RDS.id}"]
}


# kep pair

resource "aws_key_pair" "auth" {
 key_name = "${var.key_name}"
 public_key = "${file(var.public_key_path)}  
}



