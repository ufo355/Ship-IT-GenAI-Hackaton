locals {
  lex_role_name                          = "${var.name_prefix}-lex-role-${terraform.workspace}"
  lambda_lex_role_name                   = "${var.name_prefix}-lambda-lex-role-${terraform.workspace}"
 
  lambda_lex_name                        = "${var.name_prefix}-lambda-lex-${terraform.workspace}"
 
}
