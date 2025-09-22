output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id

}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}


output "aws_internet_gateway" {
  value = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.main[*].id

}