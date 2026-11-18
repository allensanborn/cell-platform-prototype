---
resource: https://github.com/kgateway-dev/kgateway.dev/tree/e1acca81e555bf7a85f75fb1beb8b7327837d796/assets/kgw-docs/pages/security/ratelimit
fetched: 2026-11-16
fetch_note: "git clone --depth 1 kgateway-dev/kgateway.dev@e1acca81e555bf7a85f75fb1beb8b7327837d796 (2026-11-16)"
---


<!-- kgateway.dev/assets/kgw-docs/pages/security/ratelimit/global.md lines 1,14 -->


Configure global rate limiting rules across all of your Gateways to protect the backing services in your cluster.

## About {#about}

Global rate limiting in {{< reuse "kgw-docs/snippets/kgateway.md" >}} is powered by [Envoy's rate limiting service protocol](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rate_limit_filter). With global rate limiting, you can apply distributed, consistent rate limits across multiple Gateways. Unlike local rate limiting, which operates per Gateway instance, global rate limiting uses a central service to coordinate rate limits. Therefore, to use global rate limiting, you must bring your own rate limit service that implements the Envoy protocol.

With your own rate limit service in place, you get benefits such as:

- Coordinated rate limiting across multiple Gateways.
- Centralized rate limit management with shared counters.
- Dynamic descriptor-based rate limits that can consider multiple request attributes.
- Consistent user experience, regardless of which Gateway receives the request.


<!-- kgateway.dev/assets/kgw-docs/pages/security/ratelimit/local.md lines 1,12 -->

Limit the number of requests that are allowed to enter the cluster before global rate limiting and external auth policies are applied.  

## About {#about}

Local {{< gloss "Rate Limiting" >}}rate limiting{{< /gloss >}} is a coarse-grained rate limiting capability that is primarily used as a first line of defense mechanism to limit the number of requests that are forwarded to your rate limit servers. 

Without local rate limiting, all requests are directly forwarded to a rate limit server that you set up where the request is either denied or allowed based on the global rate limiting settings that you configured. However, during an attack, too many requests might be forwarded to your rate limit servers and can cause overload or even failure.

To protect your rate limit servers from being overloaded and to optimize their resource utilization, you can set up local rate limiting in conjunction with global rate limiting. Because local rate limiting is enforced in each Envoy instance that makes up your gateway, no rate limit server is required in this setup. For example, if you have 5 Envoy instances that together represent your gateway, each instance is configured with the limit that you set. 

For more information about local rate limiting, see the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter). 


<!-- kgateway.dev/content/docs/envoy/latest/reference/api.md lines 4758,4772 -->

#### HTTPHeader

HTTPHeader represents a single header name/value pair. Exactly one of value or secretRef must be set. When using secretRef, name and key interact as follows: - Both present: name is the header name, key is the Secret data key. - name absent, key present: the key is also used as the header name. - name present, key absent: the name is also used as the Secret data key. - Both absent: every entry in the Secret is injected as a header (data key -> header name). 

**Validation:**
- ExactlyOneOf=value;secretRef
- XValidation:rule="has(self.value) ? has(self.name) : true",message="name is required when using an inline value"

| Field | Type | Description |
|-------|------|-------------|
| `name` | *_gwv1.HTTPHeaderName_ | Name is the HTTP header field name. Name matching is case-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2.) Required when value is set. When secretRef is used, if omitted the Secret data key is used as the header name; if both name and key are omitted every Secret entry is injected as a header. |
| `value` | *string | Value is an inline string value for the header. Mutually exclusive with secretRef. Must consist of printable US-ASCII characters. (See https://tools.ietf.org/html/rfc7230#section-3.2.) |
| `secretRef` | *[SecretRefWithKey](#secretrefwithkey) | SecretRef sources the header value from a key in a Kubernetes Secret. Mutually exclusive with value. |

#### HTTPHeaderFilter
