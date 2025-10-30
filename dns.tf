data "aws_route53_zone" "public" {
  for_each = { for x in var.dns_records : "${x.name}_${x.zone_name}_${x.set_identifier}_${x.type}" => x if local.internal != true }

  name         = each.value.zone_name
  private_zone = false
}

data "aws_route53_zone" "private" {
  for_each = { for x in var.dns_records : "${x.name}_${x.zone_name}_${x.set_identifier}_${x.type}" => x }

  name         = each.value.zone_name
  private_zone = true
}

resource "aws_route53_record" "public" {
  for_each = { for x in var.dns_records : "${x.name}_${x.zone_name}_${x.set_identifier}_${x.type}" => x if local.internal != true }

  zone_id        = data.aws_route53_zone.public["${each.value.name}_${each.value.zone_name}_${each.value.set_identifier}_${each.value.type}"].zone_id
  name           = each.value.name
  type           = each.value.type
  set_identifier = each.value.set_identifier


  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }

  dynamic "failover_routing_policy" {
    for_each = length(keys(lookup(each.value, "failover_routing_policy", {}))) == 0 ? [] : [true]

    content {
      type = each.value.failover_routing_policy.type
    }
  }

  dynamic "latency_routing_policy" {
    for_each = length(keys(lookup(each.value, "latency_routing_policy", {}))) == 0 ? [] : [true]

    content {
      region = each.value.latency_routing_policy.region
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = length(keys(lookup(each.value, "weighted_routing_policy", {}))) == 0 ? [] : [true]

    content {
      weight = each.value.weighted_routing_policy.weight
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = length(keys(lookup(each.value, "geolocation_routing_policy", {}))) == 0 ? [] : [true]

    content {
      continent   = lookup(each.value.geolocation_routing_policy, "continent", null)
      country     = lookup(each.value.geolocation_routing_policy, "country", null)
      subdivision = lookup(each.value.geolocation_routing_policy, "subdivision", null)
    }
  }
}


resource "aws_route53_record" "private" {
  for_each = { for x in var.dns_records : "${x.name}_${x.zone_name}_${x.set_identifier}_${x.type}" => x }

  zone_id        = data.aws_route53_zone.private["${each.value.name}_${each.value.zone_name}_${each.value.set_identifier}_${each.value.type}"].zone_id
  name           = each.value.name
  type           = each.value.type
  set_identifier = each.value.set_identifier


  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }

  dynamic "failover_routing_policy" {
    for_each = length(keys(lookup(each.value, "failover_routing_policy", {}))) == 0 ? [] : [true]

    content {
      type = each.value.failover_routing_policy.type
    }
  }

  dynamic "latency_routing_policy" {
    for_each = length(keys(lookup(each.value, "latency_routing_policy", {}))) == 0 ? [] : [true]

    content {
      region = each.value.latency_routing_policy.region
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = length(keys(lookup(each.value, "weighted_routing_policy", {}))) == 0 ? [] : [true]

    content {
      weight = each.value.weighted_routing_policy.weight
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = length(keys(lookup(each.value, "geolocation_routing_policy", {}))) == 0 ? [] : [true]

    content {
      continent   = lookup(each.value.geolocation_routing_policy, "continent", null)
      country     = lookup(each.value.geolocation_routing_policy, "country", null)
      subdivision = lookup(each.value.geolocation_routing_policy, "subdivision", null)
    }
  }
}
