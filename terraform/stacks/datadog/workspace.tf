# WORKSPACE VARS

locals {
  context_variables = {
    pro = {

    }
  }
}
locals {
  workspaces = merge(local.context_variables)
  workspace  = merge(local.workspaces[terraform.workspace])
}
