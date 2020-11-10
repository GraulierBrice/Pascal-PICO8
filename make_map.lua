noise = loadfile("simplex.lua")()

herbe="3e"
touffe="3f"
arbre="2f"
rocher="38"
rrocher="39"

f={rrocher, rocher, arbre, arbre, arbre, arbre, arbre, touffe, touffe, touffe, touffe, herbe, herbe, herbe, herbe}

dx=1/127
dy=1/63
fx=20 ox=1564231
fy=20 oy=4564465
for y=0, 63, 1 do
	l=""
	for x=0, 127, 1 do
		n = noise(x*dx*fx+ox, y*dy*fy+oy)
		n = math.ceil(((n+1)/2)*#f)
		l=l..f[n]
	end
	print(l)
end
