#import "@preview/ssrn-scribe:0.5.0": *
#import "@preview/note-me:0.2.1": note
#import "@preview/chronos:0.1.0"
#import "@preview/glossarium:0.4.1": *


#show link: set text(blue)
#show link: underline;
#show: make-glossary

#show: paper.with(
  font: "PT Serif",
  maketitle: true,
  title: [Sundae Protocol - Permissioned DeFi],
  subtitle: [ADA Handle DID Resolution],
  authors: (
    (
      name: "Pi Lanningham",
      affiliation: "Sundae Labs",
      email: "pi@sundae.fi",
      note: ""
    ),
    (
      name: "Jesse Anderson",
      affiliation: "Kora Labs",
      email: "papa.goose@koralabs.io",
      note: "",
    ),
    (
      name: "Justin Newton",
      affiliation: "Netki",
      email: "justin@netki.com",
      note: "",
    ),
  ),
  date: "October 2024",
  abstract: [
    DeFi protocols and cryptocurrency ecosystems often struggles to attract liquidity, in large part because of the lack of regulatory clarity. Large institutions who wish to participate hesitate to do so because DeFi primitives are usually wholly permissionless. This puts them at regulatory risk, as their funds may be utilized in trades that fund illegal activities.

    Sundae Labs, Kora Labs, and Netki are collaborating to solve this problem. This specification outlines 3 separate standards that will enable seamless permissioned DeFi on top of the by-default permissionless Sundae Protocol on the Cardano blockchain.

    + ADA Handle DID Resolution - allow a user to associate #glspl("did") with their Cardano address
    + Permissioned Pools - allow liquidity pools that have extra configurable conditions attached to specific orders
    + Netki Integration - specify exactly how to utilize the above, along with Netki's compliance oracle infrastructure

    Together, these three proposals allow the creation of "clean" DeFi pools on top of the Sundae Protocol.
  ]
)

= Introduction

The goal of this specification is to outline how Sundae Labs, Kora Labs, and Netki are collaborating to allow permissioned and regulatory compliant “Clean” pools on Cardano, leveraging ADA Handles for easy @did Discovery, the SundaeSwap protocol for DeFi primitives, and Netki as a compliance oracle.

The main thesis of this work is that DeFi is unnecessarily closed off from institutional participation because of regulatory risk. A large entity may have very deep liquidity that they would be interested in deploying to DeFi, but are unable to do so because they cannot bear the risk of those funds being used for money laundering, terrorism financing, or any other unsavory activities.

In a classical finance setting, these actors would have the assurance that the financial institutions holding the funds and executing the trades have done their due diligence such as performing @kyc on each customer executing a trade.

We strongly believe that permissionless DeFi provides options to legitimate actors in the developing world, and have spent 3 years building exactly those primitives. However, we also believe that the landscape of DeFi can provide for all users, including those that want more assurance behind who they are transacting with. Decentralized Identity standards allow entities to exchange sensitive identity information in a decentralized setting, without unduly exposing those details to the broader watching world.

#note[
  Originally, we had planned to include a proposal to extend #link("https://cips.cardano.org/cip/CIP-30", "CIP-30") to allow a dApp to communicate with a DID wallet. However, we discovered that this work is already under way via several great standards (such as #link("https://github.com/cardano-foundation/cf-identity-wallet", "this") work by the Cardano Foundation), is auxiliary to the objective of the project, and didn't make sense to duplicate that work.
]

= ADA Handle DIDs

ADA Handles are a “human readable address” product built on Cardano. By holding a Cardano Native Token with a given name at a specific address, tooling such as wallets can allow users to type in a human readable name, and unambiguously resolve that to an address.

ADA Handles follow the CIP-68 standard to allow custom data to be associated with the ADA handle. For example, this capability is used today to specify a preferred background, profile picture, and highlight color to personalize your Handle, and dApps can match their theming to that personalization information.

All CIP-68 ADA Handles begin with an asset name prefix of `000de140`. There also exists a corresponding token with a prefix of `000643b0`, and the same suffix, that corresponds to the “reference token”.

The datum holding the reference token can be updated with a signature from the wallet holding the ADA handle to prove ownership, and a signature from Kora Labs to ensure that the structure of the datum stays well formed.

The format of that datum according to CIP-68 is:

```cddl
    big_int = int / big_uint / big_nint
    big_uint = #6.2(bounded_bytes)
    big_nint = #6.3(bounded_bytes)
    metadata =
      { * metadata => metadata }
      / [ * metadata ]
      / big_int
      / bounded_bytes
    version = int
    extra = plutus_data
    datum = #6.121([metadata, version, extra])
```

The purpose of `metadata` is to capture metadata about the NFT itself, while `extra` is arbitrary and can be determined by use case. ADA Handle has utilized the `extra` field for their personalization metadata.

We propose standardizing on a `public_did` field added to this extra map in the case of ADA Handles.

The public_did field will be a @cbor map, where the keys represent a human readable label, and the values represent a W3C DID Identifier, according to #link("https://www.w3.org/TR/did-core/#did-syntax", "this specification").

```cddl
    did = bounded_bytes, ; UTF-8
    did_map =
      { * label => did }
    metadata =
      {
        ; ...
        public_did: did_map
      }
```

One of these keys can be “default”, which should indicate the DID to select in non-interactive scenarios where the user cannot be prompted.

If a dApp has some ADA Handle, and wishes to resolve a users DID, it can follow these steps:
- Strip off the `000de140` prefix from the ADA Handle
- Prepend the `000643b0` prefix to obtain the reference token name
- Look up the UTxO holding the token with the same policy ID and the reference token name
- Read the attached Datum, and deserialize it according to the CIP-68 specification
- Read the `extra.public_did` field
- Select one of the DIDs
  - If noninteractive, and one of the keys is `default`, use this one
  - If noninteractive, and there is only one DID, use this one
  - If noninteractive, and there are multiple DIDs, behavior is dependent on your use case
  - If interactive, and there is only one DID, use this one
  - If interactive, and there are multiple DIDs, prompt the user for which one to use, using the keys as labels

From there, the dApp can use existing standards, such as #link("https://didcomm.org/", "DIDComm"), #link("https://identity.foundation/keri/did_methods/", "KERI"), or others to interact with the user and their identity.

= Sundae Protocol Permissioned Pools

= Netki Compliant Pools

= Conclusion

End to end, here is a sequence diagram that illustrates how the above three protocols enable a decentralized, compliant liquidity pool.

#scale(x: 70%, y: 70%, origin: top + center)[
#chronos.diagram({
  import chronos: *
  _par("B", display-name: "Browser")
  _par("W", display-name: "Wallet")
  _par("I", display-name: "Identity Wallet")
  _par("O", display-name: "Compliance Oracle")
  _par("C", display-name: "Cardano Blockchain")
  _par("P", display-name: "Pool Script")

  _seq("B", "W", comment: [`List Assets`])
  _seq("W", "B") // Response

  _seq("B", "C", comment: [`Lookup Datum (handle)`])
  _seq("C", "B") // Response

  _seq("B", "O", comment: [`Initiate Swap (details, did)`])

  _seq("B", "I", comment: [`Request Swap (details, netki)`])
  _seq("I", "O", comment: [`Approve(signature, kyc)`])
  
  _seq("O", "B", comment: [`Approve(token)`])
  _seq("B", "B", comment: [`Build Tx`])
  _seq("B", "W", comment: [`Sign Tx`])
  _seq("W", "B")
  _seq("B", "C", comment: [`Submit Tx`])
  _seq("C", "P", comment: [`Validate Token`])
  _seq("P", "C")
  _seq("C", "B", comment: [`Confirm Tx`])
})
]

= Glossary

#print-glossary(
  (
    (
      key: "cbor",
      short: "CBOR",
      long: "Concise Binary Object Representation",
      desc: "A binary encoding format used heavily by the Cardano blockchain",
    ),
    (
      key: "did",
      short: "DID",
      plural: "DIDs",
      long: "Decentralized Identifier",
      longplural: "Decentralized Identifiers",
      desc: "A standard for creating unique identifiers for entities in a decentralized setting",
    ),
    (
      key: "b2hash",
      short: "Blake2b 256 Hash",
      desc: "A mathematical fingerprint of a set of data; a specific algorithm used heavily by the Cardano blockchain",
    ),
    (
      key: "kyc",
      short: "KYC",
      long: "Know Your Customer",
      desc: "A series of steps and data collection policies that one entity might employ so it can transact with another and verify the identify of a customer",
    )
  ),
)