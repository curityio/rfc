% title = "OAuth Assisted Token Specification"
% abbrev = "assistedtoken"

% docName = "draft-ideskog-assisted-token-00"
% area = "Internet"
% workgroup = "OAuth"
% keyword = ["oauth", "javascript", "spa", "single page application"]
%
% date = 2017-11-07T00:00:00Z
%
% [[author]]
% initials="J."
% surname="Ideskog"
% fullname="J. Ideskog"
% #role="editor"
% organization = "Curity AB"
%   [author.address]
%   email = "jacob@curity.io"
% [[author]]
% initials="T."
% surname="Spencer"
% fullname="T. Spencer"
% #role="editor"
% organization = "Curity AB"
%   [author.address]
%   email = "travis@curity.io"

# Abstract
This specification defines a flow needed to integrate single page applications (SPAs) with an OAuth authorization server. It defines the protocol needed as well as suggestions on how to wrap certain functionality in JavaScript helper libraries. This specification extends the capabilities defined in RFC6749

# Status of This Memo
This is an individual contribution intended to be taken up in the standard track of the OAuth working group of the Internet Engineering Task Force (IETF).

# Copyright Notice
Copyright (c) 2017 IETF Trust and the persons identified as the document authors.  All rights reserved.

This document is subject to BCP 78 and the IETF Trust's Legal Provisions Relating to IETF Documents   (https://trustee.ietf.org/license-info) in effect on the date of publication of this document.  Please review these documents carefully, as they describe your rights and restrictions with respect to this document. Code Components extracted from this document must include Simplified BSD License text as described in Section 4.e of the Trust Legal Provisions and are provided without warranty as described in the Simplified BSD License.

# Table of Contents
TBD

# Introduction
Section [1.3](https://tools.ietf.org/html/rfc6749#section-1.3) of the The OAuth 2.0 Authorization Framework describes the grant types included in the base specification of the OAuth 2.0 protocol. The implicit flow was intended for usage with client that cannot preserve a secret. This includes single page applications (SPAs). However a common property of SPAs is that they build state in the current page context. The implicit flow requires the user to redirect the browser to the Authorization Server and then back to the page. For many SPAs this means that the state of the page is lost, or must be rebuilt which can prove difficult or impossible. For this reason a new flow is needed that addresses these concerns seen with the implicit flow.

# Notational Conventions
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [RFC2119] [RFC8174] when, and only when, they appear in all capitals, as shown here.

# Terminology

In addition to the terms defined in referenced specifications, this document uses the following terms:

* "single page application" An application built using
* "SPA"

# Assisted Token
To simplify the integration of OAuth into Web applications, a new flow, which we refer to as the "Assisted Token Flow" in added to the OAuth server. This flow uses a new endpoint, the Assisted Token Endpoint. This is introduced rather than reusing the authorize endpoint because it alleviates the client developer from needing to specify a response_type parameter in the authorize request. This flow takes place in a dynamic iframe. After the flow completes, the AS redirects back to the application, which frames the flow, using a JavaScript call to window.postMessage. By using these two mechanisms to start and finish the flow, client developers only need to provide a client_id and write a handler for window.postMessage. Response types or other query string parameters are unnecessary. This request/response is shown in the following diagram.

The goals are:
* Reduce the complexity of the call for the developer
* Never leave the current page

Two versions:
There are two versions of the flow. One where the user never interacts with the frame, and one where the user is required to interact in order to authenticated.

## Basic flow

### Non-interactive

TODO : ASCII art of the flow

(A) The client opens a hidden iframe and makes the initial GET request passing the client_id as the only required parameter. The GET request is made by setting the "src" parameter in the iframe with the full URL to the assisted endpoint including the client_id parameter.

(B) If the Authorization Server can determine that the user has an SSO session, it issues an Access Token and shows a page.

(C) The page runs JavaScript onLoad that sends a message using postMessage with the result to the parent frame.

To force the non interactive flow above the client MAY send the "prompt=none" query string argument along with the client_id. This forces the Authorization Server as well as any Authentication Service to no prompt the user.

If the user is not logged in, an error SHOULD be returned. If the error contains "user_authentication_required", then the client can restart the flow in a visible frame. See the Interactive Flow.

### Interactive Flow

TODO : ASCII art of the flow

(A) The client opens a visible iframe and makes the initial GET request passing the client_id as the only required parameter. The GET request is made by setting the "src" parameter in the iframe with the full URL to the assisted endpoint including the client_id parameter.

(B) The Authorization Server hands over to an authenticating party that interacts with the user for Authentication.

(C) The Authorization server issues the Access Token and shows a page.

(D) The page runs JavaScript onLoad that sends a message using postMessage with the result to the parent frame.

After (D) the client closes the iframe and the flow is complete. The

### Assisted Token Request
The assisted token request is a GET request constructed by the client containing the following parameters

client_id   REQUIRED

prompt      OPTIONAL May contain the value "none" which indicates that the client wants to use an existing sso session to log the user in and not show any consent screens. If the Authorization Server cannot fulfill this it MUST respond with an error.

for_origin  OPTIONAL as described in section (TODO: Reference Origin section)

scope       OPTIONAL as described in section (TODO: Reference Scope section)

### Assisted Token Response

The response is a postMessage sent from the page on the Authorization Server in the iframe, to the client in the parent frame. This post message is a JSON object with the following parameters

#### Successful Response

access_token     REQUIRED

scope            REQUIRED only if the server changes the scopes from the default.

expires_in       REQUIRED the number of seconds until the access_token expires.


#### Error Response

error               REQUIRED an error code as defined in RFC6749#4.2.2.1 with the following addition

  user_interaction_required  
      The user is required to interact with the flow in some way. This could be to grant consent, or to authenticate.

error_description    OPTIONAL Human-readable ASCII [USASCII] text providing additional information, used to assist the client developer in understanding the error that occurred.

## Origin (for_origin)

As the Assisted Token flow is defined to run inside an iframe, it's critical to protect against click-jacking attacks and other layover attacks. This can be achieved by preventing the frame from being loaded on other domains then that of the client. The client needs to have a `for_origin` defined. If more than one `for_origin` is defined on the client, the client MUST pass the `for_origin` parameter on the query string in the initial request to allow the Authorization Server to set the correct response headers.

The Authoriation Server MUST validate the `for_origin` parameter against the whitelisted origins for the specific client. If no match is found framing should be denied.

The Authorization Server MUST include either Content Security Policy restrictions or X-Frame-Options to restrict the frame to be shown on the for_origin domain only.

## Scope (scope)
The `scope` parameter as defined in RFC6749 is used to request scopes in the Assisted Token flow. The Assisted Token Flow does not require the `scope` parameter to be sent in the request. If the parameter is omitted the Authorization Server SHOULD include *all* scopes configured on the client. This is different from the behaviour on the Authorize endpoint in that it defines a well defined behaviour of the empty `scope` parameter.


## Access Token Lifetime

## Authentication

## Revocation


# Cross-Origin Support
The Assisted Token endpoint MAY support Cross-Origin Resource Sharing (CORS) [W3C.WD-cors-20120403] if it is locked down according to the Origin policies.

# Security Considerations

## Not reusing redirect_uri
The Assisted Token does not reuse or overload the `redirect_uri` parameter for the purpuse of Origin restrictions. If the same client was configured for both implicit flow and assisted token flow, the origin configuration could open a too broad redirect that an attacker might take advantage of.

### Third party cookies
The Assisted Token flow is defined to run in an iframe. This may be affected by browser restrictions on third party cookies. Many authentication flows depend on cookies to keep state. It is up to the implementor to decide how to handle the third party cookie issue.


# References

## Normative References
[USASCII]  American National Standards Institute, "Coded Character Set -- 7-bit American Standard Code for Information Interchange", ANSI X3.4, 1986.

[RFC2119]  Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", [BCP 14](https://tools.ietf.org/html/bcp14), [RFC 2119](https://tools.ietf.org/html/rfc2119), March 1997.

[W3C.WD-cors-20120403] Kesteren, A., "Cross-Origin Resource Sharing", World Wide Web Consortium LastCall [WD-cors-20120403](http://www.w3.org/TR/2012/WD-cors-20120403), April 2012,

## Informational References

[RFC6749] Hardt, D., "The OAuth 2.0 Authorization Framework", [RFC 6749](https://tools.ietf.org/html/rfc6749), October 2012.
