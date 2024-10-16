package require topotools
proc get_total_charge {{molid top}} {
  eval "vecadd [[atomselect $molid all] get charge]"
}
mol bondsrecalc all
topo retypebonds
topo guessangles
topo guessdihedrals

puts ""
puts "Bond type names: "
puts [ topo bondtypenames ]
puts ""
puts "Angle type names: "
puts [ topo angletypenames ]
puts ""
puts "Dihedral type names: "
puts [ topo dihedraltypenames ]
puts ""
puts ""
puts [format "Number of bonds:          %s" [topo numbonds]         ]
puts [format "Number of bonds types:    %s" [topo numbondtypes]     ]
puts [format "Number of angles:         %s" [topo numangles]        ]
puts [format "Number of angles types:   %s" [topo numangletypes]    ]
puts [format "Number of dihedral:       %s" [topo numdihedrals]     ]
puts [format "Number of dihedral types: %s" [topo numdihedraltypes] ]
puts [format "Total charge:             %s" [get_total_charge]      ]
puts ""
topo writelammpsdata data.water_ethanol
