# The OAuth 2.0 Authorization Framework: Claims

## Abstract

This document extends the [OAuth 2.0 framework](https://tools.ietf.org/html/rfc6749) to include a simple query language that can be used by Clients to request certain Claims from an Authorization Server. This mechanism can be used during the authorization request and refresh request. It also defines a response parameter of the token and introspection endpoints that indicate to the caller which Claims were authorized by the Resource Owner. Lastly, it stipulates how this request parameter can be used during token exchange, and how Clients may request that certain Claims be placed in an Access Token intended for a particular Resource Server. 

This document is designed to be compatible with [OpenID Connect](https://example.com) but does not require the Authorization Server to support that protocol.

<!-- TOC -->

## 1. Introduction

As stated in [section 1.4 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-1.4), an Access Token represents the specific scope and duration of access. The requested scope is verified by the Authorization Server according to its policy, and the perhaps-different scope is granted by the Resource Owner. The requested and granted scope may vary due to the Authorization Server's policy and/or the Resource Owner's limitation of the granted scope. The resulting scope is enforced by the Resource Server. The way in which the Client indicates the intended scope of access is by the `scope` request parameter defined in section [3.3 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-3.3). This specification defines a more sophisticated instrument to achieve this same purpose.

At times, this existing mechanism is too limited. In some uses cases, for example, a Client may need to request particular Claims from an Authorization Server. It may also do this to request specific Claim Values. Furthermore, a Client may need to indicate to the Authorization Server that certain Claims are essential for its ability to operate. In such cases, the grant is of little use to the Client if the Resource Owner does not comply. Another example of when the existing `scope` parameter is insufficient is when the Client knows that some Claim is required by a particular Resource Server. The extent of a Client's knowledge is usually limited to knowing that a Claim is needed in an Access Token; however, in some cases, it may also know that a Claim should be restricted to Access Tokens issued to a particular Resource Server. In these situations, the existing mechanism for stipulating the scope of access is insufficient. 

To accommodate these use cases and requirements, this specification defines a new request parameter that can be used when the Client obtains an authorization grant, as described in [section 1.3 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-1.3) and [section 2.1 of the token exchange draft](https://tools.ietf.org/html/draft-ietf-oauth-token-exchange-19#section-2.1). For each request wherein these five grant types -- authorization code, implicit, resource owner password credentials, client credentials, and token exchange -- are sought, this specification defines a new parameter called `claims`. It can be used by a Client with any of these to request that certain Claims and/or particular Claim Values be authorized by the Resource Owner. The value of this parameter is a JavaScript Object Notation (JSON) object [[JSON](https://tools.ietf.org/html/rfc7159)]. This can also be used to indicate to the Authorization Server that the Client considers some or all of the Claims to be required. The Client can also use this object to indicate that certain Claim Values are preferred or essential to its ability to operate on behalf of the Resource Owner.

During a refresh request (as described in [section 1.5 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-1.5)), the `claims` parameter defined herein can also be used to alter the resulting scope of access. This can be used, for example, to lessen the scope by including a certain subset of Claims that should be in the new Access Token. After such, a Client may increase the scope in a subsequent refresh request by including additional Claim Names in the JSON object value of the `claims` authorization request parameter. When it does so, the Client cannot, however, expand the scope or change the Claim Values from those initially authorized by the Resource Owner.

This specification also stipulates how the authorized Claim Names are returns from an authorization request and the result of introspecting a token.

### 1.1 Claims vis-à-vis Scope Tokens

As previously stated, Claims relate to Scope Tokens. How exactly is beyond the extent of this specification. Instead, this document provides a framework in which these two constructs can be used together or independently. That said, however, there are at least three common ways that Claims will be used:

1. Not at all (in which case this specification is irrelevant).
2. In lieu of Scope Tokens.
3. Together with Scope Tokens.

The first and second option are straightforward. The third, however, will require a specification to define the relation between the two in order to achieve interoperability. For instance, OpenID Connect core specification relates Claims to Scope Tokens by grouping certain Claims into various Scope Tokens. This grouping of Claims into various Scope Tokens is RECOMMENDED when simultaneously using Claims and Scope Tokens to request authorization.

### 1.2 Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 [RFC2119].

Unless otherwise noted, all the protocol parameter names and values are case sensitive.

### 1.3 Terminology

In addition to the terms defined in the references specifications, this document uses the following terms:

"Claims Sink" is the location or destination where the Authorization Server MAY include all requested Claims that are authorized by the Resource Owner. An Access Token intended for an unspecified Resource Server or an Access Token the Client intends to send to a particular Resource Server or an ID token (when the OpenID Connect profile of this specification is used) are examples of Claims Sinks.

"Claims Request Object" has the meaning ascribed to it in section 3.

"Claims Sink Query Object" has the meaning ascribed to it in section 3.1.

"Claim Value Query Object" has the meaning ascribed to it in section 3.1.

"Critical Claim" has the meaning ascribed to it in section 3.2.

"Essential Claim" is a Claim specified by the Client as being necessary to ensure a smooth authorization experience for a specific task requested by the Resource Owner.

"Scope Token" is a case-sensitive string joined by spaces together with other such strings and included in the the `scope` request parameter of an authorization request (i.e., a `scope-token` as set forth in the ABNF of [section 3.3 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-3.3)).

"Voluntary Claim" is a Claim specified by the Client as being useful but not essential for the specific task requested by the Resource Owner.

## 2. Protocol Flow

### 2.1 Authorization Request

When a Client requests authorization from the Resource Owner indirectly via the Authorization Server, the protocol flow MAY include a query for certain Claims. Based on the policy of the Authorization Server and the delegated access of the Resource Owner certain Claims MAY be granted. Given an authorization grant, the Authorization Server informs the Client as to which Claims were actually issued (if different from those requested). This message exchange pattern is shown in Figure 1:

<pre>
+--------+                               +---------------+
| Client |--(A)- Authorization Request ->| Authorization |
|        |     (including claims request |    Server     |
|        |              parameter)       |               |
|        |                               |               |
|        |<-(B)-- Authorization Grant ---|               |
|        |                               |               |
|        |--(C)-- Authorization Grant -->|               |
|        |                               |               |
|        |<-(D)----- Access Token -------|               |
+--------+    (including granted claims) +---------------+
</pre>
<center>Figure 1. Protocol Flow that Includes Requested and Granted Claims</center>

The steps in the flow illustrated in Figure 1 are generally the same as those described in [section 1.2 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-1.2) with a few important distinctions:

* The authorization request (A) is performed indirectly via the Authorization Server and not directly to the Resource Owner.
* During the authorization request (A), the Client includes a Claims Request Object as the corresponding value of the `claims` request parameter, as described in section 3.1 below.
* After obtaining (B) and presenting the authorization grant \(C\), the response MAY include an Access Token and a possibly-empty list of Claim Names that were authorized (D). If the asserted Claims embodied by the Access Token differ from those requested (A), then the Authorization Server MUST include a list of authorized Claim Names in the authorization response (D).

### 2.2 Refresh Request

TBD

### 2.3 Token Exchange Request

TBD

## 3. The Claims Request Object

The `claims` request parameter value is a UTF-8 encoded JSON object ("Claims Request Object") specifying requested Claims. Prior to transmission to the Authorization Server it is also form-URL-encoded as appropriate. The Claims Request Object is not intended to be a mechanism that the Client may use to instruct the Authorization Server to assert specific Claims. Instead, it is a simple query language that a Client can use to request certain Claims or to specify that it would like the Authorization Server to obtain authorization from the Resource Owner for a Claim, perhaps with a particular Claim Value. The Claims Request Object provides a Client with a more structured method of requesting the scope of access that the Resource Owner authorizes it for. 

The top-level members of the Claims Request Object SHOULD include at least one Claims Sink. The only specific Claims Sink defined by this specification is `access_token`. Additionally, this specification also sets forth a mechanism by which a Client may signal to the Authorization Server which Claims it prefers to be included in an Access Token that it intends to furnish to a particular Resource Server; this is done by using an absolute URI of the target service or resource as a Claims Sink. A Claims Request Object MAY also contain the member `crit` to indicate parts of the Claims Request Object that the Authorization Server MUST understand if the `crit` member itself is understood. Other members of a Claims Request Object MAY be present; any that are not understood by the Authorization Server MUST be ignored.

An example of a Claims Request Object that is provided to the Authorization Server as the value of the `claims` request parameter during an authorization request, refresh request or token exchange request is as follows: 

<pre>
{
	"access_token" : {

	}
}
</pre>

In this non-normative example, the "access_token" property is the Claims Sink. It is the location where the Authorization Server MAY include any of the requested Claims that the Resource Owner authorizes. If the Authorization Server uses the requested Claims from a particular Claims Sink to derive or determine alternative Claims which it asserts, it is RECOMMENDED to consider the Client's request to include those alternative Claims in the same requested Claims Sink. 

### 3.1 Requesting Particular Claim Names and Claim Values

Within the Claims Request Object, a Claims Sink is associated with another JSON object ("Claims Sink Query Object"). This object contains properties that have the name of a Claim which the Client is requesting the Authorization Server to assert. The possible values associated with each of these is `null` or another JSON object ("Claim Value Query Object"). 

When the value is `null`, it indicates that the Claim with the associated Claim Name is a Voluntary Claim, and the Client has no specific requirements on the Claim Value. Conversely, when the Claim Value Query Object is not `null` it is a JSON object with the following properties:

*essential*
> OPTIONAL. Indicates whether the Claim being requested is an Essential Claim. If the value is true, this indicates that the Claim is an Essential Claim. If the value is false or if this property is not include, then the Claim is a Voluntary Claim.

*value*
> OPTIONAL. Requests that the Claim be returned with a particular value.

*values*
> OPTIONAL. Requests that the Claim be returned with one of a set of values, with the values appearing in order of preference.		

The properties `value` and `values` are mutually exclusive. If the Client sends a Claim Value Query Object with both, the Authorization Server MUST return an error as described in section XX below.

By requesting Essential Claims, the Client indicates to the Authorization Server (who indicates to the Resource Owner) that releasing these Claims will ensure a smooth authorization for the specific task requested by that Resource Owner. If the Claims are not available because the Resource Owner did not authorize their release or they are not present, the Authorization Server MUST NOT generate an error when Claims are not returned.

Other members of the Claim Value Query Object MAY be defined to provide additional information about the requested Claims. Any members of the Claims Value Query Object that is not understood by the Authorization Server MUST be ignored.

A non-normative example of the two possible types of values for a Claim Value Query Object is shown in the following listing:

<pre>
{
	"access_token" : {
		"https://exmaple.com/claim1" : null,
		"fname" : {
			"value" : "John"
		}
	}
}
</pre>

In this example, there are two Claim Names which the Client is requesting: `https://example.com/claim1` and `fname`. The values associated with these are Claim Value Query Objects. The former is a simple query where the Client has no preference on a particular value. For this reason, the Client specifies the value `null`. In the later case, the Client has more precise needs: it desires the Authorization Server to assert a Claim Value of `John` for the Claim Name `fname`. In such situations the Authorization Server MAY issue a Claim with the Claim Name `fname` but with some other Claim Value than `John`. Both are Voluntary Claims.

An example of an Essential Claim is shown in the following non-normative listing:

<pre>
{
	"access_token" : {
		"consentId" : {
			"essential" : true
		}
	}
}
</pre>

This query indicates that the Client would like the Authorization Server to issue an Access Token with a scope that includes a Claim with the Claim Name `consentId`. To ensure a smooth authorization experience at the Resource Server where the Client will present the resulting Access Token, the Client has indicated that the `consentId` Claim is required, making it an Essential Claim. 

As described above, a Client may also indicate that it wishes the Authorization Server to assert a Claim having a Claim Value that the Client has some preference for. A non-normative example of such a query is this:

<pre>
{
	"access_token" : {
		"accountId" : {
			"values" : ["act-123", "act-456"],
			"essential" : true
		},
		"paymentId" : {
			"value" : "pid-123456",
			"essential" : true
		}
	}
}
</pre>

In this example, the Client is requesting that the Authorization Server assert two Essential Claims: one named `accountId` and another named `paymentId`. In the former case, the Client requests that the Claim Value be `act-123` or `act-456`. In the later case, a Claim named `paymentId` is requested by the Client to have a Claim Value of `pid-123456`. Again, the Authorization Server MUST NOT return an error if the Resource Owner does not authorize both of these Claims or if they are non-existent. This is merely a request for a certain scope of access.

Another example inspired by the Revised Directive on Payment Services (PSD2) is shown in the following non-normative listing:

<pre>
{
	"access_token" : {
		"instructedAmount" : {
			"value" : {
				"amount" : 123.50,
				"currency" : "EUR"
			},
			"essential" : true
		},
		"debtorAccount/iban" : {
			"value" : "DE40100100103307118608",
			"essential" : true
		},
		"creditorName" : {
			"value" : "Merchant123",
			"essential" : true
		},
		"creditorAccount/iban" : {
			"value" : "DE02100100109307118603",
			"essential" : true
		},
		"remittanceInformationUnstructured" : {
			"value" : "Ref Number Merchant",
			"essential" : true		
		}
	}
}
</pre>

In this example, the Client is requesting (but not forcing) the Authorization Server to obtain authorization from the Resource Owner for five Essential Claims: `instructedAmount`, `debtorAccount/iban`, `creditorName`, `creditorAccount/iban`, and `remittanceInformationUnstructured`. The Claim Value Query Object associated with each of these Claim Names has a particular value the Client strongly prefers. One interesting case is the value of the `instructedAmount` Essential Claim; the query for the value of this Claim is a JSON object with two properties. The Authorization Server might use this Claims Request Object to obtainer the Resource Owner's consent before granting them, for instance. It might also check these values against a data source before asserting them. Based on the Resource Owner's choice or the data source lookup results, the Authorization Server may not issue the Claims at all or may do so with some other value. For example, the Authorization Server may actually find that the `instructedAmount` value requested exceeds its policy's allowed limit and only prompt the Resource Owner to authorize €100.

TODO: Move to resource indicator section

Another interesting example of how structured scope of access can be requested is shown in the following listing:

<pre>
{
	"access_token" : {
		"credentialID" : {
			"value" : "qes_eidas",
			"essential" : true
		},
		"documentDigests" : {
			"value" : {
				"hash":"sTOgwOm+474gFj0q0x1iSNspKqbcse4IeiqlDg/HWuI=",
		        "label":"Mobile Subscription Contract"
			},
			"essential" : true
		},
		"hashAlgorithmOID" : {
			"value" : "2.16.840.1.101.3.4.2.1"
		}		
	}
}
</pre>

This example shows how a Client may request Claims defined by the Electronic Signatures and Infrastructures (ESI) Protocols for remote digital signature creation. Like the previous example, the Claims Request Object for the `access_token` Claims Sink includes a Claim Value Query Object for the `documentDigests` Claim that includes a JSON object with multiple properties. 

These illustrative examples hopefully impress upon the reader the versatility of this query language and the Authorization Server's prerogative to assert any Claims with any Claim Values it chooses in its sole discretion. If the Client's needs are stronger than preferential, it MAY use the `crit` member of the Claims Request Object.

### 3.2 Critical Members of a Claims Request Object

As described previously, the Client can indicate to the Authorization Server that certain Claims are preferential or essential to the smooth operation of the Client. At times, however, the Client's needs are stronger and require certain Claims to be asserted. In such situations, the Client would rather the Authorization Server return an error than grant access with different Claims than those requested. This is not always possible for an Authorization Server, however, and a Client MUST NOT assume that the Authorization Server can be controlled in this manner. To know if this interaction pattern in supported, the Client must have a priori knowledge gained by some means not defined by this specification or by the presence of a true value in the Authorization Server's `critical_claims_supported` metadata. (See section 9 below.) An Authorization Server is RECOMMENDED to support this capability unless it cannot. When it does, the Authorization Server MUST issue any Claim denoted as critical or it MUST return an error. The error must be `invalid_claim` as described below. 

A Client indicates to the Authorization Server that it must understand certain Claims and be able to assert them by including a list of JSON Pointers [[RFC 6901](https://tools.ietf.org/html/rfc6901)] associated with the `crit` member of the Claims Request Object. Each such Claim that the elements of this list point to is a "Critical Claim". The JSON Pointers in this list MUST refer to members of the Claims Request Object and MUST NOT point to elements within the list itself. If any JSON Pointer refers to an element of the JSON Pointer list, the Authorization Server MUST return an error with a code of `invalid_request` if it supports Critical Claims. When the JSON Pointers are valid, if the Authorization Server does not understand any of the Claims pointed to by any of the elements of this list, the Authorization Server MUST return an error of `invalid_claim`. Likewise, if the Authorization Server is unable to assert a Critical Claim (and it supports Critical Claims), it MUST return the same error. If a Critical Claim is requested with a certain value (as in the following example), the Authorization Server MUST assert the Claim with that exact Claim Value. If it's not able to (e.g., because the Resource Owner does not have an attribute with that particular value), the Authorization Server MUST return an error with a code of `invalid_claim` unless it does not support Critical Claims.

A non-normative example of a Claims Request Object with a Critical Claim is shown in the following listing:

<pre>
{
	"crit" : ["/access_token/verified_claims/verification/trust_framework/value"],
	"access_token" : {
		"verified_claims" : {
			"verification" : {
				"trust_framework" : {
					"value" : "de_aml"
				}
			}
		}
	}
}
</pre>

In this example, the `value` member of the JSON object associated with `trust_framework` must be understood by the Authorization Server because it is pointed by the element of the Critical Claims list. The way in which the Authorization Server understands this particular query is beyond the scope of this specification. The only part of this example that is germane is the `crit` member of the Claims Request Object which requires the Authorization Server to understand and assert a particular Claim Value. If it cannot and if it supports Critical Claims, it must return an error.

It is not uncommon for a Claim Name to defined as a URI containing slashes ('/', %x2F). When such a Claim is critical, the escaping described in [section 3 of RFC 6901](https://tools.ietf.org/html/rfc6901#section-3) MUST be used, as in the following non-normative example:

<pre>
{
	"crit" : ["/access_token/https:~1~1example.com~1claims1"],
	"access_token" : {
		"https://exmaple.com/claim1" : null,
	}
}
</pre>

## 4. Obtaining Authorization

As stated in [section 4 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4), a request for an Access Token requires the Client to obtain authorization from the Resource Owner. As described there and above, this can be done using various grant types. To make a request for certain Claims, the `claims` request parameter defined herein is used when requesting an authorization code, implicit, resource owner password credentials, or client credentials grant type. The `claims` request parameter MAY also be used with additional grant type that use the extension mechanism defined in [section 4.5 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.5) if so profiled by some other specification.

### 4.1 Authorization Code Grant

#### 4.1.1 Authorization Request

When a Client seeks to obtain authorization using the authorization code grant type defined in section [4.1 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.1), the client MAY include the following additional query component that it sends to the authorization endpoint URI:

*claims*
> OPTIONAL. A Claims Request Object as described in Section 3.

The value of this parameter must use the "application/x-www-form-urlencoded" format defined in [Appendix B of RFC 6749](https://tools.ietf.org/html/rfc6749#appendix-B).

#### 4.1.2 Error Response

If the Authorization Server understands the `claims` request parameter but does not support it, it MUST redirect the user-agent of the Resource Owner to the Client's redirection endpoint as described in [section 4.1.2.1 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.1.2.1) with one of the following `error` values:

*claims_not_supported*
> The Authorization Server does not support the `claims` request parameter, and the Client should not use it when requesting authorization.

*invalid_request*
> The Authorization Server MAY use this less descriptive error code to indicate that the claims request parameter is not accepted. It is RECOMMENDED to use `claims_not_supported` instead, however. 

*invalid_claim*
> When a Client makes a request for a Critical Claim, and the Authorization Server cannot assert such a claim because it is invalid, unknown, or malformed, this error results.

#### 4.1.3 Access Token Response

In a non-error case, the Authorization Server MAY include details about the Claims that the Client is authorized for. This is done by augmenting the response defined in [section 4.1.4 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.1.4). In particular, the Authorization Server MAY include the following response member in the JSON object returned from the token endpoint:

*claims*
> OPTIONAL, if identical to the claims requested by the client; otherwise, REQUIRED. The space-separated Claim Names granted by the Resource Owner which denote the scope of the access token.

### 4.2 Implicit Grant

#### 4.2.1 Authorization Request

When a Client seeks to obtain authorization using the implicit grant type defined in section [4.2 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.2), the client MAY include the following additional query component that it sends to the authorization endpoint URI:

*claims*
> OPTIONAL. A Claims Request Object as described in Section 3.

The value of this parameter must use the "application/x-www-form-urlencoded" format defined in [Appendix B of RFC 6749](https://tools.ietf.org/html/rfc6749#appendix-B).

#### 4.2.2 Access Token Response

In a non-error case, the Authorization Server MAY include details about the Claims that the Client is authorized for. This is done by augmenting the response defined in [section 4.2.2 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.2.2). In particular, the Authorization Server MAY include the following response parameter included on the fragment component of the redirection URI:

*claims*
> OPTIONAL, if identical to the claims requested by the client; otherwise, REQUIRED. The space-separated Claim Names granted by the Resource Owner which denote the scope of the access token.

#### 4.1.3 Error Response

If the Authorization Server understands the `claims` request parameter but does not support it, it MUST redirect the user-agent of the Resource Owner to the Client's redirection endpoint as described in [section 4.2.2.1 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.2.2.1) with one of the following `error` values:

*claims_not_supported*
> The Authorization Server does not support the `claims` request parameter, and the Client should not use it when requesting authorization.

*invalid_request*
> The Authorization Server MAY use this less descriptive error code to indicate that the claims request parameter is not accepted. It is RECOMMENDED to use `claims_not_supported` instead, however. 

*invalid_claim*
> When a Client makes a request for a Critical Claim, and the Authorization Server cannot assert such a claim because it is invalid, unknown, or malformed, this error results.

### 4.3 Resource Owner Password Credentials Grant

#### 4.3.1 Access Token Request

When a Client seeks to obtain authorization using the resource owner password credentials grant type defined in section [4.3 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.3), the Client MAY include the following additional parameter using the "application/x-www-form-urlencoded" format per [Appendix B of RFC 6749](https://tools.ietf.org/html/rfc6749#appendix-B) with a character encoding of UTF-8 in the HTTP request entity-body:

*claims*
> OPTIONAL. A Claims Request Object as described in Section 3.

#### 4.3.2 Access Token Response

In a non-error case, the Authorization Server MAY include details about the Claims that the Client is authorized for. This is done by augmenting the response defined in [section 4.3.3 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.3.3). In particular, the Authorization Server MAY include the following response member in the JSON object returned from the token endpoint:

*claims*
> OPTIONAL, if identical to the claims requested by the client; otherwise, REQUIRED. The space-separated Claim Names the Client is authorized for which denote the scope of the access token.

If the request is invalid due to the value of this parameter, the Authorization Server returns an error with one of the following error codes:

*claims_not_supported*
> The Authorization Server does not support the `claims` request parameter, and the Client should not use it when requesting an access token.

*invalid_request*
> The Authorization Server MAY use this less descriptive error code to indicate that the claims request parameter is not accepted. It is RECOMMENDED to use `claims_not_supported` instead, however. 

*invalid_claim*
> When a Client makes a request for a Critical Claim, and the Authorization Server cannot assert such a claim because it is invalid, unknown, or malformed, this error results.

### 4.4 Client Credentials Grant

#### Access Token Request 

When a Client seeks to obtain authorization using the client credentials grant type defined in section [4.4 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.4), the Client MAY include the following additional parameter using the "application/x-www-form-urlencoded" format per [Appendix B of RFC 6749](https://tools.ietf.org/html/rfc6749#appendix-B) with a character encoding of UTF-8 in the HTTP request entity-body:

*claims*
> OPTIONAL. A Claims Request Object as described in Section 3.

#### Access Token Response

In a non-error case, the Authorization Server MAY include details about the Claims that the Client is authorized for. This is done by augmenting the response defined in [section 4.4.3 of RFC 6749](https://tools.ietf.org/html/rfc6749#section-4.4.3). In particular, the Authorization Server MAY include the following response member in the JSON object returned from the token endpoint:

*claims*
> OPTIONAL, if identical to the claims requested by the Client; otherwise, REQUIRED. The space-separated Claim Names the Client is authorized for which denote the scope of the access token.

If the request is invalid due to the value of this parameter, the Authorization Server returns an error with one of the following error codes:

*claims_not_supported*
> The Authorization Server does not support the `claims` request parameter, and the Client should not use it when requesting an access token.

*invalid_request*
> The Authorization Server MAY use this less descriptive error code to indicate that the claims request parameter is not accepted. It is RECOMMENDED to use `claims_not_supported` instead, however. 

*invalid_claim*
> When a Client makes a request for a Critical Claim, and the Authorization Server cannot assert such a claim because it is invalid, unknown, or malformed, this error results.

## 5. Token Refresh

## 6. Token Exchange

## 7. Token Introspection 

## 8. Requesting Claims for a Particular Protected Resource

As described in the [Resource Indicators for OAuth 2.0 draft specification](https://tools.ietf.org/html/draft-ietf-oauth-resource-indicators-08) and in the introduction of this document, there are occasions when a Client may need to signal to the Authorization Server which Resource Servers it intends to submit an access token to. Using the mechanism defined there -- namely the `resource` request parameter -- results in "the requested access rights of the token [being] the cartesian product of all the scopes at all the target services." This crossproduct may produce access tokens that are too widely scoped per Resource Server. The specification explains how access can be downscoped to avoid this. That specification does not provide a way for the originally granted access to be constrained to a different scope per Resource Server though. As a result, this downscoping is only possible from the fully granted scope to some subset. This is pictographically shown in the following figure:

Granted Scope of Access for resources
  \- Down

When only Scopes Tokens are used or only Claims are used instead (option one and two from section 1.1 above), then this limitation is inconsequential. When option three -- using both Claims and Scope Tokens together, however, it is possible to perform more fine-grained downscoping of an access token. To see how, consider the following non-normative example where various Claims are grouped together into various Scope Tokens.

| Scope Token | Claims                       |
|-------------|------------------------------|
| calendar    | appointments scheduling      |
| contacts    | contacts_read contacts_write |

In this example, the granted scope of "calendar contacts" is equivalent to the set of Claims [appointments, scheduling, contacts_read, contacts_write]. What some Client may wish to achieve is to restrict the scope of any access token issued to the Resource Server available at http://calendar.example.com to only the Claims in 

## 9. Authorization Server Metadata

An Authorization Server that supports the `claims` request parameter SHOULD declare this fact by including the following property in the Authorization Server metadata response ([RFC 8414](https://tools.ietf.org/html/rfc8414#section-3.2)):

*claims_parameter_supported*
> OPTIONAL. A boolean value indicating that the Authorization Server supports the `claims` request parameter or not. A value of true indicates that it is supported. A value of false, a null value, or the absence of the property means that the `claims` request parameter is not supported by the Authorization Server. 	

*critical_claims_supported*
> OPTIONAL. A boolean value indicating that the Authorization Server supports the possibility for the Client to indicate that certain parts of a Claims Request Object MUST be understood by the Authorization Server. A value of false, a null value, or the absence of this member means that the Authorization Server MAY not support this interaction pattern, and the Client MUST NOT assume that it does.

If the Authorization Server returns a value of false for `claims_parameter_supported` and true for `critical_claims_supported`, the interpretation by the Client is undefined. It is RECOMMENDED that the Client assume that the Authorization Server is misconfigured and that it not attempt to request claims in a manner defined by this specification.

A non-normative example of an Authorization Server metadata response which indicates that the `claims` request parameter is supported is shown in the following listing:

<pre>
HTTP/1.1 200 OK
Content-Type: application/json

{
	"issuer" : 
		"https://server.example.com",
	"authorization_endpoint" : 
		"https://server.example.com/authorize",
	"token_endpoint" : 
		"https://server.example.com/token",
	"token_endpoint_auth_methods_supported" : 
		["client_secret_basic", "private_key_jwt"],
	"token_endpoint_auth_signing_alg_values_supported" : 
		["RS256", "ES256"],
	"userinfo_endpoint" : 
		"https://server.example.com/userinfo",
	"jwks_uri" : 
		"https://server.example.com/jwks.json",
	"registration_endpoint" : 
		"https://server.example.com/register",
	"scopes_supported" : 
		["openid", "profile", "email", "address", "phone", "offline_access"],
	"response_types_supported" : 
		["code", "code token"],
	"service_documentation" : 
		"http://server.example.com/service_documentation.html",
	"ui_locales_supported" : 
		["en-US", "en-GB", "en-CA", "fr-FR", "fr-CA"],
	"claims_parameter_supported" : true,
	"critical_claims_supported" : true
}
</pre>	

Note the last two members in particular.

## 10. Security Considerations 

## 11. Privacy Considerations

## 12. IANA Considerations

## 13. Normative References

TBD

## Appendix A. Acknowledgments 

## Appendix B. Document History




