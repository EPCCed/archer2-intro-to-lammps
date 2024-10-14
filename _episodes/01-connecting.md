---
title: "Connecting to ARCHER2 and transferring data"
teaching: 10
exercises: 20
questions:
- "How can I access ARCHER2 interactively?"
objectives:
- "Understand how to connect to ARCHER2."
keypoints:
- "ARCHER2's login address is `login.archer2.ac.uk`."
---

## Purpose

Attendees of this course will get access to the ARCHER2 HPC facility.
You will have the ability to request an account and to login to ARCHER2 before the course begins.
In this session, we will talk you through getting access to ARCHER2.
Please be aware that you will need to follow the [ARCHER2 Code of Conduct](https://www.archer2.ac.uk/training/code-of-conduct/) as a condition for access.

Note that if you are not able to login to ARCHER2 and do not attend this session,
you may struggle to run the course exercises as these were designed to run on ARCHER2 specifically.

## Connecting using SSH

The ARCHER2 login address is

```
login.archer2.ac.uk
```
{: .language-bash}

Access to ARCHER2 is via SSH using **both** a password and a passphrase-protected SSH key pair.

## Passwords and password policy

When you first get an ARCHER2 account, you will get a single-use password from the SAFE which you will be asked to change to a password of your choice.
Your chosen password must have the required complexity as specified in the [ARCHER2 Password Policy](https://www.archer2.ac.uk/about/policies/passwords_usernames.html).

The password policy has been chosen to allow users to use both complex, shorter passwords and long, but comparatively simple passwords.
For example, passwords in the style of both `LA10!£lsty` and `correcthorsebatterystaple` would be supported.

## SSH keys

As well as password access, users are required to add the public part of an SSH key pair to access ARCHER2.
The public part of the key pair is associated with your account using the SAFE web interface.
See the ARCHER2 User and Best Practice Guide for information on how to create SSH key pairs and associate them with your account:

* [Connecting to ARCHER2](https://docs.archer2.ac.uk/user-guide/connecting/)

## MFA/TOTP

Multi-factor authentication, under the form of timed one-time passwords, are now mandatory on ARCHER2 accounts.
To create one, please follow the instructions in our [SAFE documentation](https://docs.archer2.ac.uk/user-guide/connecting/#mfa-time-based-one-time-passcode-totp-code).

## Data transfer services: scp, rsync

ARCHER2 supports a number of different data transfer mechanisms.
The one you choose depends on the amount and structure of the data you want to transfer and where you want to transfer the data to.
The two main options are:

* `scp`: The standard way to transfer small to medium amounts of data off ARCHER2 to any other location
* `rsync`: Used if you need to keep small to medium data-sets synchronised between two different locations

More information on data transfer mechanisms can be found in the ARCHER2 User and Best Practice Guide:

* [Data management and transfer](https://docs.archer2.ac.uk/user-guide/data/)

{% include links.md %}

