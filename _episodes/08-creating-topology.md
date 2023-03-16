---
title: "Creating a topology file"
teaching: 30
exercises: 0
questions:
- "How do I create a topology file for my system?"
---


## PACKMOL

[PACKMOL](https://m3g.github.io/packmol/) can create an initial point for MD simulations by packing molecules in defined regions of space.
Installation instructions can be found in the [user guide](https://m3g.github.io/packmol/userguide.shtml#comp).

To pack a new system you will need a packmol input script and topology files for however many molecules your system has.
The molecule topology files are commonly `.xyz` files, but packmol also accepts `.pdb`, `moldy`, and `tinker`.

As an example in this lesson, we will use `water.xyz` and `ethanol.xyz`, see the end of this lesson.


### PACKMOL input script

A minimum input script must contain:

The distance tolerance required

```
tolerance 2.0
```

measeured in angstrom, 2.0 is a good value for atomistic simulations, you may want to use higher values for coarse-grained systems.

The name of and filetype for the output file:

```
output water_ethanol_mix.xyz
filetype xyz
```

the default filetype is `pdb`, packmol also accepts `xyz`, `tinker`, and `moldy`.

And at least one molecule, using a `structure ... end structure` section.
In this example, we will have two.

```
structure water.xyz
  number 2000
  inside cube 15. 15. 30. 50.
end structure
```



The first line starts the `structure` section, and selects which file to read the molecule from, in this case `water.xyz`.
Then `number` selects how many molecules the final system will have.
The next line, the contraint, selects how the molecules will be arranged in the final system, in this case, on a cube, with side `50` angstrom, and with origin at (15, 15, 30).

There are several types of constraints available: `fixed`, `constrain rotations`, combinations of `inside`/`outside` with `cube`/`box`/`sphere`/`ellipsoid`/`cylinder`, as well as combinations of `above`/`below` with `plane`/`xgauss`.
Descriptions of all of these types can be found in [the manual](https://m3g.github.io/packmol/userguide.shtml#types).

You can also combine constrains, for example, here we constrain the ethanol molecules to be in a square prism, with `1 < x < 79`, `1 < y < 79`, and `1 < z < 109`, but outside the cube where the water molecules are.

```
structure ethanol.xyz
  number 2000
  inside box 1. 1. 1. 79. 79. 109.
  outside cube 15. 15. 30. 50.
end structure
```

The extra angstrom around the limits allows the later application of periodic boundary conditions without creating bonds between atoms of different molecules.


> ## Tip
>
> To solvate large molecules/particles (for example, polymers), it is considerably faster to do multi-stop packing, with different input files, one per molecule type, and using the `fixed` constraint for the topology with the already packed molecules.
> Example:
> ```
> tolerance 2.0
> output polymers_with_water.xyz
> filetype xyz
> structure packed_polymers.xyz
>   number 1
>   fixed 0. 0. 0. 0. 0. 0.
> end structure
> structure water.xyz
>   number 2000
>   inside cube 1. 1. 1. 99.
> end structure
> ```
{: .callout}

> ## water.xyz
>
> The topology file for water.
> 
> > ## Solution
> > 
> > 3
> > Water molecule
> > WO          0.00000        0.00000        0.11779
> > WH          0.00000        0.75545       -0.47116
> > WH          0.00000       -0.75545       -0.47116
> > 
> {: .solution}
{: .challenge}



> ## ethanol.xyz
>
> The topology file for ethanol.
> 
> > ## Solution
> > 
> > 9
> > Ethanol
> >   EHC      1.8853     -0.0401      1.0854
> >   ECH      1.2699     -0.0477      0.1772
> >   EHC      1.5840      0.8007     -0.4449
> >   EHC      1.5089     -0.9636     -0.3791
> >   ECO     -0.2033      0.0282      0.5345
> >   EHA     -0.4993     -0.8287      1.1714
> >   EHA     -0.4235      0.9513      1.1064
> >   EOH     -0.9394      0.0157     -0.6674
> >   EHO     -1.8540      0.0626     -0.4252
> > 
> {: .solution}
{: .challenge}
