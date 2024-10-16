# U2F
This role configures U2F for sudo and polkit. It sets U2F as single factor (be smart and use something like a Yubi Key Bio so you have 2 factors) with password fallback.

You have to initialize the `u2f_mappings` variable which is a list with one line per user, as created by `pamu2fcfg`.

Example:

```yaml
u2f_mappings:
  - "user1:aaaaaaa,bbbb,es256,+presence"
  - "user2:ccccccc,dddd,es256,+presence"
```

