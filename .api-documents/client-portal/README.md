# Client Portal API — Front-end Guide

The web portal for people at Managed Clients (client admins, transport managers, facility managers). Design reference:
`Client Portal.dc.html`. Built in phases; this folder grows with each phase (see the list below).

Sign-in is already built: for now it is documented in [../convoy-os/clients.md § 5](../convoy-os/clients.md#5-client-portal-sign-in).

## Documents

| Area | Document |
| --- | --- |
| Sign in, pick an organisation, password | [../convoy-os/clients.md § 5](../convoy-os/clients.md#5-client-portal-sign-in) (moves here in phase 1) |

## Conventions

The shared rules (JSON in snake_case, `{ data }` answers, the error format, rate limits, signed file links) are in
[../README.md](../README.md). Every Portal call uses the Bearer token of scope `portal_account` (security scheme
`portalAuth`); a Convoy OS token is refused.
