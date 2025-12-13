jq_filter='select(
  (.objectRef.resource == "secrets" and .verb == "get" and (.user.username | contains("monitoring"))) or
  (.objectRef.resource == "pods" and .verb == "create" and .requestObject.spec.containers[0].securityContext.privileged == true) or
  (.objectRef.subresource == "exec" and .verb == "create" and .objectRef.namespace == "kube-system") or
  (.verb == "delete" and (.objectRef | tostring | contains("audit-policy"))) or
  (.objectRef.resource == "rolebindings" and .verb == "create" and .requestObject.roleRef.name == "cluster-admin")
)'

jq -s "map($jq_filter) | flatten" audit.log > audit-extract.json
