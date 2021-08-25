# Protocol of the Hypermedia Authentication API

## Abstract

This document describes a protocol of the Hypermedia Authentication API. 

## Status of this Memo

This is a public draft shared under the terms of the Open Web Foundation agreement to garner feedback and encourage early adoption prior to submission to a standards body.

## Copyright Notice

Copyright (C) 2021 Curity AB. All rights reserved.

## Table of Contents

<!-- TOC -->

## 1. Introduction

Login and authentication are often integrated into applications using the OAuth 2.0 Framework ([RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)) and the OpenID Connect ([OIDC](https://openid.net/specs/openid-connect-core-1_0.html)) protocols. These, in turn, use the HTTP standard for message transfer. The contents of these are encoded in HTML and rendered by a Web browser. As a result, login of actual people is done by those people operating a Web browser that renders these HTML-encoded representations of the login resources, regardless of the form of authentication (i.e., the credential) that is used.

Unrelated to login, OAuth, and OpenID Connect, a set of principles has emerged for creating network-based software that is interconnected using HTTP. This architectural style is known as Representational state transfer (REST) ([FIELDING](https://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm)). Data and capabilities that are exposed to other actors within a network following these principles are known as a Web Application Programming Interface (AKA a Web API or, if understood from a certain context, simply an API).

The OpenID Connect standard states in its preamble that the protocol "enables Clients to verify the identity of the End-User based on the authentication performed by an Authorization Server ... in an interoperable and REST-like manner." Here, the manner in which login is done is said to be "REST-like" because the protocol does not adhere to the all principles of REST, and only part of the protocol is defined as a Web API. The way in which complete adherence to the principles of REST can be achieved is undefined by the specification. 

The clients referred to in the above quote are often Web- and mobile-device-based applications. In the former case, this has traditionally meant that the Web application is hosted on a Web server. This deployment model allows a client to authenticate itself to an OAuth authorization server and the framework defines mechanisms for doing this. More and more, however, both Web- and mobile-device-based applications are being deployed in a way that they cannot authenticate themselves to an authorization server. Web applications are built as Single Page Applications (SPA) where any user of the Web page can view the source code (including any credential) of the entire application; likewise, mobile applications can be readily decompiled and credentials deployed with them can be obtained. This state of affairs means that clients communicating with an authorization server cannot be attested to be authentic; they are effectively "public" (i.e., unauthenticated) clients.

Because OAuth and OpenID Connect 1) do not adhere to all REST principles, 2) do not define how to authenticate a person with any particular credential, and 3) are tightly bound to the use of a browser by the authenticated user, many challenges have arisen which this specification seeks to overcome. For instance, clients running on mobile applications must delegate authentication to a browser running on that device. This leads to a suboptimal User Experience (UX), and can pose a barrier to authentication for many users. A subset of the OAuth protocol referred to as the "Resource Owner Password Credentials Grant" is sometimes shoehorned into an implementation to provide API-driven login. This is suboptimal, however, because it cannot support authentication with other kinds of credentials besides a password (and, thus, does not support multiple factors of authentication, MFA, without applications having to resort to custom solution outside the specification), it only defines a simple request/response protocol, and it does not adhere to all of the REST principles.

For these reasons and others, an alternative protocol is needed that can address these challenges. Such a protocol is described below.

### 1.1. Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 ([RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119)) ([RFC 8174](https://datatracker.ietf.org/doc/html/rfc8174)) when, and only when, they appear in all capitals, as shown here.

This specification uses the terms "access token", "refresh token", "authorization server", "resource server", "authorization endpoint", "authorization request", "authorization response", "token endpoint", "grant type", "access token request", "access token response", and "client" defined by The OAuth 2.0 Authorization Framework ([RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)).

Additionally, this specification defines and uses the following terms:

1. HAAPI    - Hypermedia Authentication API
2. CAT      - Client Attestation Token
3. SPA      - Single Page Application

## 2. Protocol Overview

An authorization server (in the OAuth and OpenID Connect sense of the term) supporting this specification provides an REST API that authenticates users operating attested client applications. This interaction is shown in figure 1:

```text
+--------------------+                                   Token   +--------------------+
|                    |              CAT                  endpoint|                    |
|                    +--(A)---------------------------->o--------+                    |
|                    |                                           |                    |
|                    |<-(B)--------------------------------------+                    |
|                    |  API AT                                   |                    |
|                    |                              Authorization|                    |
|                    |   API AT & PoP                    endpoint|                    |
|                    +--(C)---------------------------->o--------+                    |
|                    |                                           |                    |
|                    |                             Authentication|                    |
|       OAuth        |   API AT & PoP              endpoint      |    Authorization   |
|      Client        +--(D)---------------------------->o--------+       Server       |
|    Application     |       Login / authentication of user      |                    |
|                    |               API AT & PoP                |                    |
|                    |                                           |                    |
|                    |                              Authorization|                    |
|                    |       LT, API AT & PoP            endpoint|                    |
|                    +--(E)---------------------------->o--------+                    |
|                    |                                           |                    |
|                    ---(F)--------------------------------------+                    |
|                    |                Access Token               |                    |
+--------------------+                                           +--------------------+
```

> Figure 1: The integration of an OAuth client application with an authorization server 

The steps a client makes to obtain an access token are thus:

(A) The OAuth client application, in possession of a Client Attestation Token (CAT) obtained by the process depicted in figure 1 and 2 below, uses the OAuth "Client Credential Grant" as a representation of the appropriate consent. This CAT is a JSON Web Token (JWT) which is verified using the Assertion Framework for OAuth 2.0 Client Authentication and Authorization Grants.

(B) The authorization server issues an API Access Token (AT) that is bound to the private key that was used to sign the CAT.

\(C) The client performs a proof of possession of a private key that was bound to the API AT and sends this PoP and the API AT to the authorization server. This is a call to the root of the API. This is the entry into the login state machine, and the response is a root object, as described below.

(D) The client again performs a PoP and sends this with the API AT to one of the actions in the list of actions that can be performed on the resource. This continues for any number of steps. It may result in errors (not depicted in figure 1). If the user traverses to the final state of the automaton (meaning they are successfully authenticated by some means), they are logged in.

(E) The client sends another request to the authorization point together with another PoP and the API AT to the authorization endpoint. 

(F) Seeing that the user has authenticated, the authorization server finally issues it an Access Token (distinct and for a wholly separate purpose than the API AT).

### 2.1 Adherence to REST

This authorization server exposes an API that follows all of the principles of REST. Namely, it provides access to resources using Universal Resource Locators (URLs), representations of those resources are specified using media types, and the connections between those resources are provided using link relationships. The API facilitates authentication of a person using any mechanism. In other words, the actual credential used to identify and verify a person can be extended by any programmatic method. The addition of new credential types may require extensions to the content returned from the API, but the representation is extensible and can support this. This makes the API universal and able to be augmented with new login methods. It is possible for clients of the API to tolerate this kind of change because they are hypermedia clients that follows link relations in the same manner for either new or existing login resources. 

The client (which is a mobile app, a Web browser or other kind of user agent) invokes this API, specifying which representations of a resource it prefers. Any implementation of this specification may then return a single or list of supported media types (i.e. representations). In the case of a list of supported media types, the client may determine which of these is preferred and makes subsequent requests for this kind of content (i.e. content type). The client may forgo this initial content negotiation and perform it with each request for each resource if it prefers or is required.

The various representations of login and consent resources allows client applications besides simple HTML Web browsers to more easily guide a user through the process of extensible and dynamically-defined authentication and consent steps. This could involve single or multiple factors of authentication. This is made possible, in part, by the hypermedia representation of the login resources described below and further in ([MODEL](draft-spencer-haapi-model.md])). 

The authorization server returns a set of links for each resource that the client requests. These links represent transitions in a state machine. The authorization server maintains this state machine and makes it available via the API. It provides the client with the ability to traverse this state machine. States may be initial states, intermediate ones, and terminal states (both error and non-error final states). The entry and exit actions from the automaton utilize the framework defined by OAuth.

To simplify the traversal of this state machine by the API client, the authorization server MUST represent each resource (a state in the state machine) in a syntax that is easy for clients to parse and process. This resource formatting uses JavaScript Object Notation (JSON) to create an expression of a login resource. This representation (with any potential metadata) allows a client to manipulate the state of that object as necessary for that client and/or the user of that client.

As previously stated, the initial invocation of the API is done using the OAuth and/or OpenID Connect standards. The difference to them, however, is that the client specifies that it wishes to interact with the authorization server using a JSON-based content type. This is done using HTTP-based content negotiation. An example of this is shown in listing 1 and 2:

```text
1.01| GET /dev/authn/register/create/example1 HTTP/1.1
1.02| Host: example.com:8443
1.03| Accept: application/vnd.curity.auth+json
1.04| Authorization: DPoP (... API AT ...)
1.05| DPoP: (... PoP ...)
```

> Listing 1: Example HTTP request to the API where content negotiation is used to request a login resource

```text
2.01| HTTP/1.1 200 OK
2.02| Content-Type: application/vnd.curity.auth+json; charset=utf-8
2.03|
2.04| {
2.05|   "type": "example-transaction",
2.06|   "properties": {
2.07|     "autostarttoken": "2f0ddb78-1d1a-48e4-9e8a-2ba13cf0ca3b",
2.08|     "status": "pending"
2.09|   },
2.10|   "actions": [
2.11|     {
2.12|       "template": "form",
2.13|       "kind": "cancel",
2.14|       "model": {
2.15|         "href": "https://example.com:8443/dev/authn/authenticate/example1/cancel",
2.16|         "method": "POST",
2.17|         "type": "application/x-www-form-urlencoded",
2.18|         "actionTitle": "Cancel"
2.19|       }
2.20|     }
2.21|   ],
2.22|   "links": [
2.23|     {
2.24|       "href": "https://localhost:8443/dev/authn/authenticate/example1/poller",
2.25|       "rel": "self"
2.26|     },
2.27|     {
2.28|       "href": "example:///?autostarttoken=2f0ddb78-1d1a-48e4-9e8a-2ba13cf0ca3b&redirect=null",
2.29|       "rel": "example-app-launch",
2.30|       "title": "Start the Bank security app"
2.31|     }
2.32|   ]
2.33| }
```

> Listing 2: Example HTTP response from the API that shows the representation of a state in the login automaton

Using media types and performing content negotiation like this is typical of any REST API.

This hypermedia type, which represents the login and consent steps within the authentication process exposed by the API, has a root object with four properties: 1) a type, which defines the meaning of the current representation, including schematic and semantics for the sub-properties; 2) sub-properties which represent specific fields and are extensible and typed based on the value of the type property; 3) actions which is a list of actions that can be taken based on the representation; and 4) links which are related resources.

The type that a representation may assume is defined in an extensible catalog of the API specification. This includes, but is not limited to, such types as authentication step, active device, polling status, OAuth authorization response, device activation, etc.

The actions list is composed of zero or objects. Each object includes the fields 1) template, which the type of user interaction defined by the action; 2) kind, which indicates to the client additional information about the type of user interface that can be rendered in order to improve the UX; and 3) model, which is a set of fields specific to the defined template.

The link list is composed of one or more objects. Each represents a link to a related resource. Each link object includes the fields 1) href, a URI for the link target; 2) rel, which indicates the relationship of the current resource to the linked one; 3) title, which is a label describing the associated resource; and 4) the kind, which may include additional information about the related resource and can optionally be used by a client to provide an improved UX.

### 2.3 Client Attestation 

Another important aspect of the API is that public clients (again, those that do not authenticate) must attest to their identity by using features of the environment in which they are executing. This attestation is required in order to obtain an API Access Token (API AT in figure 1). Only once the client has obtained an API AT can it interact with the API and start the authentication of a user. In order to obtain an API AT, the client uses a standard OAuth flow (the so called "Client Credentials Grant"), authenticating with another token that attests to its identity. This use of the CAT is shown in figure 1 as well. The specific method by which a Web-browser-based client obtains a CAT is not defined by this protocol and left as an implementation detail. In general, however, the process for such clients as well as non-Web-browser-based clients is shown in figure 2. Once the client authenticates using the CAT and obtains an API AT, every API call performed during login must contain a Proof of Possession (PoP) of a private key that only the client has. This ensures that an attested client cannot start the login process and an unattested one finishes it. The mechanism for providing a proof of possession follows the OAuth DPOP protocol for doing so.

In more detail, proof of authenticity can be obtained from clients using any platform-specific system available to it which can perform attestation. The way in which it does this is illustrated in figure 2:

```text
         +----------------+
         |                |
         |   Attestation  |
         |     System     |
         |                |
         +---+--------+---+
             ^        |
     Request |       (D) Attestation
attestation (C)       |
             |        |
             |        v              CAT
         +---+--------+---+          endpoint +---------------+
         |                |--(E)------->o-----+               |
         |                | Challenge   ^     | Authorization |
         |      SDK       | response    |     |    Server     |
         |                |             |     |               |
         |                |--(B)--------+     |               |
         +---+--------+---+ Challenge request +---------------+
             ^        |
      Load   |       (F) CAT
       SDK  (A)       |
             |        v    
         +---+--------+---+
         |                +
         |                |
         |  OAuth Client  |
         |                |
         |                +
         +----------------+
```

> Figure 2: OAuth client application obtaining a CAT using an attestation system available within the execution environment

This system consists of:

(A) The OAuth client loads an OPTIONAL but RECOMMENDED SDK

(B) The SDK (or the client directly if applicable) requests a challenge from the authorization server

\(C) The SDK (or client if an SDK is not used) requests attestation from the provided attestation system available in the execution environment. 

(D) The attestation system provides some form of attestation

(E) The SDK (or client as applicable) encodes the attestation in a challenge response and submits it to the CAT endpoint of the authorization server. Upon, success, the authorization server responds with a CAT.

(F) The SDK (if applicable) posts the CAT to the OAuth client application via a private, secure channel.

Step (F) of Figure 2 is followed by step (A) in Figure 1.

## 2. CAT Request / Response Protocol

How a client (or the SDK it uses) to obtain a CAT is described in the following subsections. Each request made to the server MAY contain additional parameters. The authorization server MUST ignore these if not understood. Sending any defined parameter without a value MUST be treated as if the client (or its SDK) did not send them.

### 2.1 Requesting a CAT

A OAuth client needs to obtain a Client Attestation Token (CAT) to prove its identity before obtaining an API AT. As shown in step (B) of Figure 2 above, the begins by requesting a challenge from the authorization server. This is a simple GET request with the client identifier provided on the query string. An example is shown in Listing 3:

```text
3.01| GET /haapi/cat?client_id=my_good_client HTTP/1.1
3.02| Host: example.com
```

> Listing 3: Example of fetching a challenge from the CAT endpoint

A successful response to such a request MUST use the HTTP 200 status code and may be any media type that the client (or SDK) understands (e.g., `text/html`, `applicaton/json`, `application/jwt`, etc.). An example response is shown in Listing 4:

```text
4.01|HTTP/1.1 200 OK
4.02|
4.03|Content-Type: application/html
4.04|
4.05|<html></html>
```
> Listing 4: Example response to requesting a challenge from the CAT endpoint

If the client fails to include the require `client_id` request parameter, the server MUST respond with an HTTP 400 status code. The body MAY include an error description in the body.

### 2.2 Responding to the CAT Challenge

Once the SDK (or client) has obtained an attestation, it needs to encode it as a challenge response and post it to the authorization server's CAT endpoint. It does this by using the same URI (including the `client_id` query string parameter) used to obtain the challenge, but uses the POST HTTP method. The body of the request MUST include the original challenge in the `challenge` parameter and the response in the `challenge_response` parameter. These parameters MUST be form-URL encoded.

A non-normative example of such an HTTP request (with extra line breaks added for clarity) is shown in Listing 5:

```text
5.01|POST /haapi/cat?client_id=my_good_client HTTP/1.1
5.02|Host: example.com
5.03|Content-Type: application/x-www-form-urlencoded
5.04|
5.05|challenge=...&
5.06|challenge_response=...
```

> Listing 5: An example of posting a challenge response to the authorization endpoint

A successful response to such a request MUST use the HTTP 200 status code. The contents of the response body MUST a JSON object and have the content type `application/json`. The JSON object MUST have one property called `cat`. This MUST be the CAT that the client (or SDK) can use to obtain an API AT from the token endpoint. A non-normative example of such a response is shown in Listing 6:

```text
6.01|HTTP/1.1 200 OK
6.02|Content-Type: application/json
6.03|
6.04|{
6.05|    "cat": "..."
6.06|}
```

If the SDK (or client) that makes the request uses any other content type (e.g., JSON), the authorization server MUST respond with an HTTP 400 status code and MAY include an error description in the body. If the required parameters, `challenge` and `challenge_response`, are not included in the request, the authorization server MUST respond with an HTTP 400 status code and MAY include an error description in the body. The client MAY omit the `client_id` on the query string and the authorization server MUST not produce an error if it is not included.

## 3. Obtaining an API AT using a CAT

As shown in step (A) of Figure 1, the client (or its SDK) use the CAT to obtain an API AT from the authorization server's token endpoint. The way in which it does this is by using the client credential grant type described in [section 4.4 of RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4). As such, the request MUST be form-URL encoded and contain the `grant_type` parameter with a value of `client_credentials`. The `scope` parameter MAY also be included, but the `client_id` parameter need not be included.

This request MUST use the CAT to authenticate the client. The way in which this CAT is used to authenticate the client is described in [section 4 of RFC 7521](https://datatracker.ietf.org/doc/html/rfc7521#section-4). Specifically, the CAT must be the value of the `client_assertion` parameter, and the `client_assertion_type` used in the request MUST be `urn:se:curity:attestation:client`. The client MUST only use the CAT once, and the authorization server MUST reject any request containing a CAT that was previously submitted to it.

The request MUST also include a `DPoP` request header as defined in [section 4.1 of DPoP](https://www.ietf.org/archive/id/draft-ietf-oauth-dpop.html). The private key used to sign the DPoP proof JWT MUST be the same key used to sign the attestation (step D in Figure 2). The authorization server MUST ensure that no other key was used to sign the DPoP proof JWT than the one used to sign the attestation.

A successful response will be as described in [section 4.4.3 of RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4.3). The `token_type` MUST be `DPoP`. The token in the `access_token` field of the JSON object is the API AT used to call the HAAPI to perform user login.

## 4. Using an API AT to Invoke HAAPI

TBD

## 5. Security Considerations

TBD

## 6. IANA Considerations

TBD

## Acknowledgements

The author would like to thank Mike Schwartz and others for their valuable input, feedback and general support of this work.

## Authors' Addresses

Travis Spencer
Curity
Email: travis.spencer@curity.io

Renato Athaydes
Curity
Email: renato.athaydes@curity.io

Pedro Felix
Curity
Email: pedro.felix@curity.io
