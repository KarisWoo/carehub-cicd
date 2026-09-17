package main

# Règle personnalisée CareHub : aucune image ne doit utiliser un tag flottant :latest.
deny[msg] {
  some name
  service := input.services[name]
  image := service.image
  endswith(image, ":latest")
  msg := sprintf("service %s: le tag :latest est interdit", [name])
}

# Les services critiques doivent avoir un healthcheck.
deny[msg] {
  some name
  service := input.services[name]
  name != "proxy"
  not service.healthcheck
  msg := sprintf("service %s: healthcheck obligatoire", [name])
}

# Les services applicatifs ne doivent pas embarquer de secret littéral évident.
deny[msg] {
  some name
  service := input.services[name]
  env := service.environment
  some key
  val := env[key]
  contains(lower(key), "password")
  is_string(val)
  not startswith(val, "${")
  msg := sprintf("service %s: %s doit être injecté via variable/secrets", [name, key])
}
