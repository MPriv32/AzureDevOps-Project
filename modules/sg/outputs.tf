output "allow_winrm" {
  value = aws_security_group.allow_winrm.id
}

output "allow_rdp" {
  value = aws_security_group.allow_rdp.id
}