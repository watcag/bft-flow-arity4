def split(xmin,xmax,ymin,ymax,n,level,start_index,pattern):

    m = int(start_index/n)
    print("create_pblock {pblock_level_",level,"_", start_index,"",start_index+n,"}",sep='')
    print("resize_pblock [get_pblocks {pblock_level_",level,"_", start_index,"",start_index+n,"}] -add {CLOCKREGION_X",xmin,"Y",ymin,":CLOCKREGION_X",xmax,"Y",ymax,"}",sep='')
    switch_type = pattern[(level-1) % len(pattern)]
    for switches in range(n):
        if level > 0:
            print("add_cells_to_pblock [get_pblocks {pblock_level_",level,"_", start_index,"",start_index+n,"}] [get_cells -quiet [list {n2.ls[",level,"].ms[",m,"].ns[",switches,"].",switch_type,"_level.sb}]]",sep='')
        else:
            print("add_cells_to_pblock [get_pblocks {pblock_level_",level,"_", start_index,"",start_index+n,"}] [get_cells -quiet [list {xs[",start_index+switches,"].",switch_type,"_level0.sb}]]",sep='')

    if n==1:
        return
    else:
        xmid, ymid = xmin+(xmax-xmin)//2, ymin+(ymax-ymin)//2
        split(xmin, xmid, ymin, ymid, int(n/4), level-1, start_index, pattern)
        split(xmid, xmax, ymin, ymid, int(n/4), level-1, start_index + int(1*n/4), pattern)
        split(xmin, xmid, ymid, ymax, int(n/4), level-1, start_index + int(2*n/4), pattern)
        split(xmid, xmax, ymid, ymax, int(n/4), level-1, start_index + int(3*n/4), pattern)


import sys
import math
N = int(sys.argv[1])
Topo = sys.argv[2]

if Topo == "TREE":
    pattern = ["d4u1"]
elif Topo == "MESH0":
    pattern = ["d4u2"]
elif Topo == "MESH1":
    pattern = ["d4u4", "d4u2", "d4u2"]
elif Topo == "XBAR":
    pattern = ["d4u4"]

level=int(math.log2(N)/2)

xmin = 0
xmax = 5
ymin = 0
ymax = 14
start_index=0
split(xmin,xmax,ymin,ymax,N//4,level-1,start_index,pattern)
