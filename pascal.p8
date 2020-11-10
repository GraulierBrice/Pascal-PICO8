pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-->8 main
	days_per_ticks={{6,2/3},{3,1/3},{1.5,1/6}}
	game_speed=1
	game_phase=1
	day=1
	month=1
	year=1519
	days=0
	game_pause=false
	game_start=0

	function time_speed()
		return days_per_ticks[game_speed][game_phase]
	end

	function _init()
		init_player()
		init_camera()
		if (game_start==0) music(0)
	end

	function _update()
		update_mouse()
		if(game_start==0 or game_start==2)return
		update_npcs()
		update_camera()
		update_player()
		update_quests()
		
		ts=time_speed()
		days+=ts
		day+=ts
		if(day>30)then
			day=day-30
			month+=1
			building_maintence()
			if(month>12)then
				month=1
				year+=1
				if(year>=2019) gameover()
			end
		end
		

	end

	function _draw()
		draw_camera()
		draw_map()
		draw_roads()
		if(game_start==1)then
		draw_npcs()
		draw_player()
		draw_build_box()
		draw_menus()
		elseif(game_start==0)then draw_start()
		elseif(game_start==2)then gameover()
		end
		draw_mouse()
	end

	function gameover()
		game_start=2
		start_submenu=0.1
		printui("voici votre valbonne",25,56,5+day,7)
		printui("votre score est "..resources[7],30,64,5+day,7)
		cam_move_to(flr((-cos(time()/30)+1)*448),flr((cos(time()/50)+1)*64))
		if(mouse.lp)then run() end
	end

-->8 start

show_start_menu=false
function draw_start()
		day=day%1.95+0.05
		if(not show_start_menu and mouse.lp)then show_start_menu=true mouse.lp=false end
		if(show_start_menu)then draw_start_menu()
		else printui("cliquez pour commencer",20,60,5+day) end

		cam_move_to(flr((-cos(time()/30)+1)*448),flr((cos(time()/50)+1)*64))
		spr(204,95+cam.x,95+cam.y,2,2)
		spr(206,111+cam.x,95+cam.y,2,2)
		spr(204,111+cam.x,111+cam.y,2,2,true,true)
		spr(206,95+cam.x,111+cam.y,2,2,true,true)
	end

start_submenu=0
function draw_start_menu()
	if(start_submenu==0)then
		draw_clear_box(abs_box(32,52,97,81))
		if btnui("commencer",48,54)then start_submenu=0.5
		elseif btnui("options",51,64)then start_submenu=1
		elseif btnui("quitter",51,74)then show_start_menu=false start_submenu=0 end
	elseif(start_submenu==1)then
		draw_clear_box(abs_box(32,32,97,97))
		if(btnui("couleur : "..ceil(player.color)..'/14',34,44)) player.color=(player.color)%14+1
		if(btnui("yeux : "..ceil(player.eye)..'/7',34,54)) player.eye=(player.eye+1)%7
		if(player.gender==1)then
			if(btnui("genre : homme",34,64)) player.gender=0
		else
			if(btnui("genre : femme",34,64)) player.gender=1
		end
		if(btnui("tourner",34,74)) player.dir=(player.dir<3) and player.dir+1 or 0
		player.box=box(62+cam.x,83+cam.y,5,7)
		if(btnui("retour",34,84))then start_submenu=0 player.box=box(512,112,5,7) end

		draw_char(player)
	elseif start_submenu==0.5 then
			draw_clear_box(abs_box(32,52,97,81))
			labels={"rapide (15m)","moyen (30m)","lent (60m)"}
			l=labels[game_speed]
			if(btnui(l,67-#l*2,54)) game_speed=(game_speed)%#days_per_ticks+1
			if(btnui("jouer",57,64)) play()
			if(btnui("retour",55,74)) start_submenu=0
	end
end
function play()
	game_start=1 _init() day=0
end

-->8 player
	player={}
	resources={10,0,1,100,100,0,0}
	--gold,tech,pop,def,env,prosp,score

	game_mode=0--0 is classic,1 is build mode

	function init_player()
		if (player) then
			col=player.color
			eye=player.eye
		end
		player=new_char(512,112)
		player.dir=0
		if (col and eye) then
			player.color=col
			player.eye=eye
		end
	end

	function update_player()
		move_player()
		if(btnp(4) and facing_npc>0 )then
			interact_npc(facing_npc)
			npcs[facing_npc].dir=3-player.dir
		elseif(mouse.lp and hovered_npc>0)then
			interact_npc(hovered_npc)
		end
	end

	function draw_player()
		draw_char(player)
	end

	function move_player()
		dx=(btn(0) and-1 or 0)+(btn(1) and 1 or 0)
		dy=(btn(2) and-1 or 0)+(btn(3) and 1 or 0)
		move_char(player,dx,dy)
	end

	function interact_npc(i)
		if npcs[i].special then
			npcs[i].special()
		else
			toggle_dialog_menu=true
			disp_msg(rnd_dialogs[ceil(rnd(#rnd_dialogs))])
			moves[''..i]=nil
		end
	end

	function can_afford(p)
		for i=1,#p,1 do
			if(resources[i]+p[i]<0) return false
		end
		return true
	end

-->8 map


	function add_map(spr,x,y,nx,ny,tx,ty)
		nx=(nx or 2)-1
		ny=(ny or 2)-1
		tx=(tx or nx+1)-1
		ty=(ty or ny+1)-1
		rx=flr(max(nx/tx,0))
		ry=flr(max(ny/ty,0))
		rx=max(nx/tx,0)
		ry=max(ny/ty,0)
		for a=0,tx,1 do
			for b=0,ty,1 do
				if((a==0 and (b==0 or b==ty)) or (a==tx and (b==0 or b==ty)))then mset(x+a,y+b,spr+a*rx+16*b*ry)
        elseif(a==0 or a==tx)then mset(x+a,y+b,spr+16*flr(ny/2)+a*rx)
				elseif(b==0 or b==ty)then mset(x+a,y+b,spr+nx/2+16*b*ry)
				else mset(x+a,y+b,spr+flr(nx/2)+16*flr(ny/2)) end
				if((a==0 and (b==0 or b==ty)) or (a==tx and (b==0 or b==ty)))then mset(x+a,y+b,spr+flr(a*rx+16*b*ry+0.5))
        elseif(a==0 or a==tx)then mset(x+a,y+b,spr+flr(16*ny/2+a*rx+0.5))
				elseif(b==0 or b==ty)then mset(x+a,y+b,spr+flr(nx/2+16*b*ry+0.5))
				else mset(x+a,y+b,spr+flr(nx/2+16*ny/2+0.5))end
			end
		end
	end

	function draw_map()
		mx=flr(cam.x/8)
		my=flr(cam.y/8)
		map(mx,my,mx*8,my*8,17,17)
	end

-->8 collisions
	col_map={}

	function col_add_box(b)
		for x=b.l,b.r,1 do
			col_map[x.." "..b.t]=true
			col_map[x.." "..b.b]=true	
			if(x==b.l or x==b.r)then
				for y=b.t+1,b.b-1,1 do
					col_map[x.." "..y]=true
				end
			end
		end
	end

	function col_move_box(b,dx,dy,fm)
		if(dx==0 and dy==0) return b
		newb=cpy(b)
		if(fm==nil) fm=col_free_move(b,dx,dy)
		if fm.x then newb.l+=dx newb.r+=dx end
		if fm.y then newb.t+=dy newb.b+=dy end
		for x=b.l,b.r,1 do
			for y=b.t,b.b,1 do
				col_map[x.." "..y]=nil
			end
		end
		col_add_box(newb)
		return newb
	end

	function col_get_point(x,y,m)
		if((m==0) and band(0b1,fget(mget(flr(x/8),flr(y/8)))) !=0)then
			if(band(0b10,fget(mget(flr(x/8),flr(y/8))))!=0) return nil else return true
		end
		if((m==1) and band(0b1,fget(mget(flr(x/8),flr(y/8)))) !=0 or band(0b10,fget(mget(flr(x/8),flr(y/8))))!=0) return true
		if(col_map[x.." "..y] !=nil) return true
		return nil
	end

	function col_free_box(b,m)
		for x=b.l,b.r,1 do
			for y=b.t,b.b,1 do
				if(col_get_point(x,y,m)) return false
			end
		end
		return true
	end

	function col_free_move(b,dx,dy)
		fm={x=true,y=true}
		if dx !=0 then
			if(dx>0) x=b.r+1
			if(dx<0) x=b.l-1
			for y=b.t,b.b,1 do
				fm.x=(col_get_point(x,y,0)==nil)
				if(not fm.x) break
			end
		end
		if dy !=0 then
			if(dy>0) y=b.b+1
			if(dy<0) y=b.t-1
			for x=b.l,b.r,1 do
				fm.y=(col_get_point(x,y,0)==nil)
				if(not fm.y) break
			end
		end
		if(dx!=0 and dy!=0 and fm.x and fm.y)then
			if(dx>0)then x=b.r+1 else x=b.l-1 end
			if(dy>0)then y=b.b+1 else y=b.t-1 end
			if(col_get_point(x,y,0) !=nil) return {x=false,y=false}
		end
		return fm
	end

-->8 npcs
	npcs={}
	
	hovered_npc=0
	facing_npc=0

	moves={}
	function update_npcs()
		hovered_npc=0
		facing_npc=0

		dirs={{4,12},{-4,4},{11,4},{4,-4}}
		d=dirs[player.dir+1]

		for i=1,#npcs,1 do
			
			if(facing_npc==0 and is_in_box(player.box.l+d[1],player.box.t+d[2],npcs[i].box)) facing_npc=i
			if(hovered_npc==0 and hoverworld(npcs[i].box)) hovered_npc=i

			if not npcs[i].special then
				if moves[''..i] !=nil then
					move_char(npcs[i],moves[''..i][2],moves[''..i][3])
					moves[''..i][1]-=1
					if(moves[''..i][1]<=0) moves[''..i]=nil
				elseif(rnd()>0.9)then
					dx=flr(rnd(3))-1
					if(dx==0)then dy=flr(rnd(3))-1 else dy=0 end
					moves[''..i]={8,dx,dy}
				end
			end
		end
	end

	function draw_npcs()
		for npc in all(npcs) do
			draw_char(npc)
			if(npc.special) spr(7,npc.box.l,npc.box.t-8)
		end
	end

	function new_char(x,y)
		npc={
			color=flr(rnd(15))+1,
			eye=rnd(7),
			box=box(x or flr(rnd(500)),y or flr(rnd(250)),5,7),
			gender=flr(rnd(2)),
			anim=0,
			dir=flr(rnd(4)),
		}
		
		if(npc.color==11) npc.color=3
		col_add_box(npc.box)
		return npc
	end

	function draw_char(c)
		if(not is_in_box(c.box.l,c.box.t,box(cam.x-8,cam.y-8,135,135))) return
		pal(7,c.color)--main color
		sspr(0,0,8,6,c.box.l,c.box.t+c.anim)
		sspr(0,((c.dir==1 or c.dir==2) and 7 or 6),8,1,c.box.l,c.box.b+c.anim-1)--body
		pal(7,7)--back to white
		if(c.dir<2)sspr(8+c.eye%8,0+flr(c.eye/8),1,2,c.box.l+2,c.box.t+2+c.anim)--eyes
		if(c.dir==0 or c.dir==2)sspr(8+c.eye,0,1,2,c.box.l+4,c.box.t+2+c.anim)--eyes
		if(c.gender==0)then
			if(c.dir<2) pset(c.box.l+1+c.dir*2,c.box.t+c.anim+4,14)--
			if(c.dir==0 or c.dir==2) pset(c.box.l+5-c.dir,c.box.t+c.anim+4,14)
		end
		c.anim=(c.anim+rnd(0.1))%2
	end

	function move_char(c,dx,dy)
		if(not is_in_box(c.box.l,c.box.t,box(cam.x-8,cam.y-8,135,135))) return
		fm=col_free_move(c.box,dx,dy)
		fm.x=fm.x and not (c.box.l<0 and dx<0 or c.box.r>=1023 and dx>0)
		fm.y=fm.y and not (c.box.t<=0 and dy<0 or c.box.b>=255 and dy>0)
		if dx<0 then c.dir=1
		elseif dx>0 then c.dir=2 end
		if dy<0 then c.dir=3
		elseif dy>0 then c.dir=0 end
		c.box=col_move_box(c.box,dx,dy,fm)
	end

-->8 camera
	cam={x=0,y=0}
	cam_bounds={}
	function init_camera()
		cam_bounds=abs_box(48,48,80,80)
		--if (game_start==1) then cam.x=0 cam.y=0 end
	end

	function update_camera()
		cam_follow(player.box)
	end

	function draw_camera()
		cls()
	end

	function cam_move_to(x,y)
		cam.x=min(896,max(0,x))
		cam.y=min(128,max(0,y))
		camera(cam.x,cam.y)
	end

	function cam_focus(b)
		cam_move_to(b.l-64,b.t-64)
	end

	function cam_follow(b)
		dx=0
		dy=0
		--b=box_w2s(b)
		c=box_s2w(cam_bounds)

		if(b.l<c.l) dx+=b.l-c.l
		if(b.r>c.r) dx+=b.r-c.r
		if(b.t<c.t) dy+=b.t-c.t
		if(b.b>c.b) dy+=b.b-c.b

		cam_move_to(cam.x+dx,cam.y+dy)
	end

-->8 mouse
	mouse={}

	function update_mouse()
		get_mouse()
	end

	function get_mouse()--get mouse info (magical stuff)
		poke(0x5f2d,1)
		x=min(max(0,stat(32)),127)
		y=min(max(0,stat(33)),127)
		l=(band(stat(34),1)==1)
		r=(band(stat(34),2)==2)
		wu=(stat(36)>0)
		wd=(stat(36)<0)
		lp=mouse and l and not mouse.l or not mouse and l
		rp=mouse and r and not mouse.r or not mouse and r
		wup=mouse and wu and not mouse.wu or not mouse and wu
		wdp=mouse and wd and not mouse.wd or not mouse and wd
		mouse={x=x,y=y,l=l,r=r,lp=lp,rp=rp,wu=wu,wd=wd,wup=wup,wdp=wdp}
	end

	function draw_mouse()--draw the cursor
		s=2
		if(game_mode==1 and (selected_building>=0 or selected_road>=0))then s=3
		elseif(game_mode==0 and hovered_npc>0 and game_start==1)then s=6 end
		spr(s,mouse.x-2+cam.x,mouse.y-1+cam.y)
	end

-->8 menu

	function draw_menus()
		draw_main_menu()
		draw_res_menu()
		draw_dialogs_menu()
	end

	toggle_res_menu=true
	function draw_res_menu()
		if(toggle_res_menu)then
			i={10,11,0,13,12,14,15}
			draw_clear_box(box(0,0,27,71))
			
			printui(str_num(flr(resources[1]),4),11,3,7)
			sprui(i[1],1,2)
			printui(str_num(flr(resources[2]),4),11,13,7)
			sprui(i[2],1,12)
			printui(str_num(flr(resources[3]),4),11,23,7)
			sprui(i[3],1,22)
			printui(str_num(flr(resources[4]),3),11,33,7)
			printui('%',23,33,7)
			sprui(i[4],1,32)
			printui(str_num(flr(resources[5]),3),11,43,7)
			printui('%',23,43,7)
			sprui(i[5],1,42)
			printui(str_num(flr(resources[6]),4),11,53,7)
			sprui(i[6],1,52)
			printui(str_num(flr(resources[7]),4),11,63,7)
			sprui(i[7],1,62)

			draw_clear_box(box(29,0,11,11))
			if(btnsprui(8,31,2)) toggle_res_menu=false
		else
			draw_clear_box(box(0,0,11,11))
			if(btnsprui(9,2,2)) toggle_res_menu=true
		end
	end

	toggle_main_menu=true
	submenu=0
	function draw_main_menu()
		if(toggle_main_menu)then
			draw_clear_box(abs_box(0,90,127,127,0))
			if submenu==0 then
				if(btnui("construction",2,92)) submenu=1
				if(btnui("liste",2,102)) submenu=2
			elseif submenu==1 then
				if(btnui("construire",2,92))then
					game_mode=1
					selected_building=1
					selected_road=0
					submenu=1.1
				end
				if(btnui("route",2,102))then
					game_mode=1
					selected_building=0
					selected_road=1
					submenu=1.2
				end
				if(btnui("detruire",2,112))then
					game_mode=1
					selected_building=0
					selected_road=0
					submenu=1.3
				end
				if(btnui("retour",102,92))then
					game_mode=0
					selected_building=-1
					selected_road=-1
					submenu=0
				end
			elseif submenu==1.1 then
				b=buildings[selected_building]
				printui(b[1],2,92,7)
				printui("cout    :",2,101,7)
				printui("gain    :",2,110,7)
				printui("mensuel :",2,119,7)
				l1=0
				l2=0
				l3=0
				sprs={10,11,0,13,12,14,15}
				for i=1,#b[5],1 do
					if(b[5][i]<0)then
						printui(str_num(ceil(-b[5][i]),3),37+l1*24,101,7)
						sprui(sprs[i],49+l1*24,99)
						l1+=1
					elseif(b[5][i]>0)then
						printui(str_num(b[5][i],3),37+l2*24,110,7)
						sprui(sprs[i],49+l2*24,108)
						l2+=1
					end
					if(b[6][i]>0)then
						printui(str_num(b[6][i],3),37+l3*24,119,7)
						sprui(sprs[i],49+l3*24,117)
						l3+=1
					end
				end
				if(btnui("retour",102,92))then
					game_mode=0
					selected_building=-1
					selected_road=-1
					submenu=1
				end
			elseif submenu==1.2 then
				b=roads[selected_road]
				printui(b[1],2,92,7)
				if(btnui("retour",102,92))then
					game_mode=0
					selected_building=-1
					selected_road=-1
					submenu=1
				end
			elseif submenu==1.3 then
				printui("detruire",2,92,7)
				if(btnui("retour",102,92))then
					game_mode=0
					selected_building=-1
					selected_road=-1
					submenu=1
				end
			elseif submenu==2 then
				list={}
				for v in all(built) do
					list[buildings[v[1]][1]]=list[buildings[v[1]][1]] or 0
					list[buildings[v[1]][1]]+=1
				end
				i=0
				for k,v in pairs(list) do
					printui(k..": "..v,2,92+10*i,7)
					i+=1
				end
				if(btnui("retour",102,92))then
					submenu=0
				end
			end
			draw_clear_box(box(0,77,11,11))
			if(btnsprui(5,2,79)) toggle_main_menu=false
			txt=str_num(flr(day),2).."/"..str_num(flr(month),2).."/"..str_num(flr(year),4)
			draw_clear_box(box(85,80,42,8))
			printui(txt,87,82,7)
		else
			draw_clear_box(box(0,116,11,11))
			if(btnsprui(4,2,118)) toggle_main_menu=true
			txt=str_num(flr(day),2).."/"..str_num(flr(month),2).."/"..str_num(flr(year),4)
			draw_clear_box(box(85,119,42,8))
			printui(txt,87,121,7)
		
		end
	end

	msg=""
	nchars=0
	function disp_msg(m)
		toggle_dialog_menu = true
		nchars=0
		msg=m
	end

	toggle_dialog_menu=false
	function draw_dialogs_menu()
		if(toggle_dialog_menu)then
			draw_clear_box(abs_box(46,0,127,40))

			for i=0,nchars/20,1 do
				strl=20*i
				endl=min(20*(i+1)-1,nchars)
				printui(sub(msg,strl,endl),48,2+6*i,7)
			end

			if(nchars>0 and nchars<#msg) sfx(0)

			nchars=min(#msg,nchars+1)

			if(btnui("ok!",115,34)) toggle_dialog_menu=false

			draw_clear_box(box(116,42,11,11))
			if(btnsprui(6,118,44)) toggle_dialog_menu=false
		else
			draw_clear_box(box(116,0,11,11))
			if(btnsprui(6,118,2)) toggle_dialog_menu=true
		end
	end

-->8 ui elements
	function btnui(txt,x,y)
		b=txt_box(txt,x,y)
		if hover(b)then c=7 else c=6 end
		printui(txt,x,y,c)
		return mouse.lp and c==7
	end

	function btnsprui(s,x,y)
		b=spr_box(x,y)
		sprui(s,x,y)
		return mouse.lp and hover(b)
	end

	function hover(r)
		return is_in_box(mouse.x,mouse.y,r)
	end

	function hoverworld(r)
		return is_in_box(mouse.x+cam.x,mouse.y+cam.y,r)
	end

-->8 quests

	function update_quests()
		q1()
		tq()
		prospq()
		popq()
		sq()
		if(year==1969) then 
			disp_msg("l'ere technologique est arrivee ! construisez votre technopole sophia.")
			game_phase=2
		end
	end


	_q1={status=0}
	function q1()
		if(_q1.status==0 and time()>2)then
			_q1.npc=new_char(player.box.l+32,player.box.t)
			add(npcs,_q1.npc)
			_q1.npc.special=function()
				disp_msg("construis-moi une maison ! (menu construction,construire,clic droit)")
			end
			_q1.status=1
		elseif(_q1.status==1 and #built>0)then
			toggle_dialog_menu=true
			disp_msg("oh super ! merci beaucoup. tu peux detruire les arbres avec l'option detruire.")
			add_resources({5,0,0,0,0,0,0})
			_q1.npc.special=nil
			_q1.t=time()
			_q1.status=2
		end
	end

	_sq={status=0}
	function sq()
		if(resources[4]<80 and _sq.status==0)then resources[2]*=0.8 disp_msg("par crainte de crime une partie de la population est partie") _sq.status=1
		elseif(resources[4]<50 and _sq.status==1)then 
			destroy(1,built[ceil(rnd(#built))]) 
			disp_msg("un batiment a ete detruit par une bataille de gang") _sq.npc=new_char(player.box.l+32,player.box.t) 
			add(npcs,_sq.npc)
			_q1.npc.special=function()
				disp_msg("il y a trop de crime il faut regler ce probleme !")
			end
			_sq.status=2
		elseif(resources[4]<20)then resources[1]*=0.99 end
		if(resources[4]<=0)gameover()
	end


	_tq={status=0}
	function tq()
		if(_tq.status==0 and resources[2]>=10)then
			add(buildings,{"milice",26,3,3,{-40,0,3,0,0,0,20},{0,0,0,.4,0,0,0},24,68})
			newbuild("une milice")
			_tq.status=1
		elseif(_tq.status==1 and resources[2]>=40)then
			add(buildings,{"marche",21,3,2,{-100,0,3,0,0,10,30},{.3,0,0,0,0,0,0},4,68})
			newbuild("un marche")
			_tq.status=2
		elseif(_tq.status==2 and resources[2]>=50)then
			add(buildings,{"infirmerie",75,2,2,{-50,0,1,0,0,20,30},{0,0,0,.1,0,0,0},7,68})
			newbuild("une infirmerie et des routes pavees")
			add(roads,{"route pavee",{0,0,0,0,0,0,0},{0,0,0,0,0,0,0},8,16,17})
			_tq.status=3
		elseif(_tq.status==3 and resources[2]>=50)then
			add(buildings,{"taverne",192,3,3,{-100,0,1,0,0,20,30},{.35,0,0,-0.3,0,0,0},24,68})
			newbuild("une taverne")
			_tq.status=4
		elseif(_tq.status==4 and resources[2]>=250)then
			add(buildings,{"ecole",77,3,3,{-500,0,5,0,0,25,150},{0,.2,0,0,0,0,0},12,68})
			newbuild("une ecole")
			_tq.status=5
		elseif(_tq.status==5 and resources[2]>=1200)then
			add(buildings,{"immeuble",128,2,3,{-2000,0,12,0,0,100,400},{.6,0,0,-.05,-.09,0,0},20,68})
			newbuild("un immeuble")
			_tq.status=6
		elseif(_tq.status==6 and resources[2]>=2000)then
			add(buildings,{"usine",141,3,3,{-2000,0,7,0,0,60,400},{1,.5,0,-.2,-.2,0,0},30,68})
			newbuild("une usine et des routes goudronees")
			add(roads,{"route goudronee",{0,0,0,0,0,0,0},{0,0,0,0,0,0,0},0,16,16})
			_tq.status=7
		elseif(_tq.status==7 and resources[2]>=2500)then
			add(buildings,{"poste de police",64,3,3,{-500,0,3,0,0,0,500},{0,0,0,1,-.01,0,0},24,68})
			newbuild("un poste de police")
			_tq.status=8
		elseif(_tq.status==8 and resources[2]>=3500)then
			add(buildings,{"supermarche",137,3,3,{-1500,0,3,0,0,100,500},{0.9,0,0,0,-.1,0,0},16,68})
			newbuild("supermarche")
			_tq.status=9
		elseif(_tq.status==9 and resources[2]>=6969)then
			add(buildings,{"polytech",130,4,4,{-9000,0,30,0,0,1000,2000},{0,0,0,1,-.01,0,0},36,68})
			newbuild("l'universite de polytech nice-sophia")
			_tq.status=10
		end
	end

	function newbuild(str)
		disp_msg("grace a vos avances technologiques vous pouvez maintenant construire "..str.." !")
	end

	_prospq={status=0}
	function prospq()
		i=_prospq.status
		if(resources[6]>50+50*i*i)then
			resources[1]+=50*(i+1)
			resources[2]+=5*i
			_prospq.status+=1
			disp_msg("la ville prospere !")
		end
	end

	_popq={status=0}
	function popq()
		i=_popq.status
		if(resources[3]>10*i)then
			_popq.status+=1
			add(npcs,new_char(396+rnd(256),56+rnd(112)))
		end
	end


	function neg(t)
		n={}
		for i=1,#t,1 do
			add(n,-t[i])
		end
		return n
	end

	function add_resources(r,t)
		t=t or resources
		for k,v in pairs(r) do
			t[k]=min(t[k]+v,9999)
		end
		t[4]=min(t[4],100)
		t[5]=min(t[5],100)

	end

-->8 utils
	function str_num(n,d)
		str=''..n
		for i=0,d-#str-1,1 do str='0'..str end
		return n<1 and sub(str,2) or str
	end

	function printui(t,x,y,c)
		print(t,x+cam.x,y+cam.y,c)
	end

	function sprui(s,x,y)
		spr(s,x+cam.x,y+cam.y)
	end

-->8 boxes
	function box(x,y,w,h)
		return {l=x,t=y,r=x+w,b=y+h}
	end

	function abs_box(l,t,r,b)
		return {l=l,t=t,r=r,b=b}
	end
	
	function spr_box(x,y)
		return box(x,y,8,8)
	end
	
	function txt_box(str,x,y)
		return box(x,y,4 * #str,5)
	end
	
	function is_in_box(x,y,b)
		return x>=b.l and x<=b.r and y>=b.t and y<=b.b
	end

	function clear_box(b)
		rectfill(b.l,b.t,b.r,b.b,0)
	end

	function draw_box(b,c)
		c=c or 7
		line(b.l+1,b.t,b.r-1,b.t,c)
		line(b.l,b.t+1,b.l,b.b-1,c)
		line(b.r,b.t+1,b.r,b.b-1,c)
		line(b.l+1,b.b,b.r-1,b.b,c)
	end

	function draw_clear_box(b)
		clear_box(box_s2w(add_box(abs_box(1,1,-1,-1),b)))
		draw_box(box_s2w(b))
	end

	function box_w2s(b)
		return abs_box(b.l-cam.x,b.t-cam.y,b.r-cam.x,b.b-cam.y)
	end

	function box_s2w(b)
		return abs_box(b.l+cam.x,b.t+cam.y,b.r+cam.x,b.b+cam.y)
	end

	function add_box(b1,b2)
		return abs_box(b1.l+b2.l,b1.t+b2.t,b1.r+b2.r,b1.b+b2.b)
	end

-->8 buildings
    buildings={
		{"maison",24,2,2,{-5,0,3,0,0,5,10},{.05,0,0,-.01,0,0,0},4,68},
		{"eglise",73,2,3,{-20,0,1,2,0,10,30},{.04,0,0,0,0,0,0},20,68},
		{"moulin",71,2,3,{-30,0,1,0,0,0,20},{.1,.03,0,0,0,0,0},10,68},
		{"vigne",29,2,2,{-30,0,1,0,0,5,20},{.12,0,0,0,0,0,0},1,68}
	}
	unbuilt={}
    built={}
	selected_building=-1
	selected_road=-1

	function cpy(orig)
		new={}
		for k,v in pairs(orig) do
			new[k]=v
		end
		return new
	end

  function build(sbox)
		if(selected_road>0)then
			b=roads[selected_road]
			add_road(sbox.l,sbox.t)
			w=1
			h=1
			res=b[2]
			mntc=b[3]
			s=b[6]
			add_resources(res)
			add_resources(mntc,maintence)
		elseif(selected_building>0)then			
			b=buildings[selected_building]
			w=b[3] h=b[4]
			res=b[5]
			add_resources(res)
			buildings[selected_building][5][1]*=1.15
			s=b[8]
        	bx=sbox
        	add(unbuilt,{selected_building,bx,b[7]})
		end
		add_map(s,sbox.l/8,sbox.t/8,(s==68 and 3 or w),(s==68 and 3 or h),w,h)
  end

	function destroy(bflag,b)
		if(bflag==1)then
			add_resources(neg(buildings[b[1]][6]),maintence)
			for i=0,buildings[b[1]][3]-1,1 do
				for j=0,buildings[b[1]][4]-1,1 do
					add_map(63,i+b[2].l/8,j+b[2].t/8,1,1)
				end
			end
			del(built,b)	
		elseif(bflag==2)then
				add_resources(neg(roads[b[1]][3]),maintence)
				destroy_road(b)
				add_map(63,b[2]/8,b[3]/8,1,1)
		else
				add_map(63,(b.l/8),(b.t/8),1,1)
		end
	end

	maintence={0,0,0,0,0,0,0}
	function building_maintence()
				resources[5]+=20
        add_resources(maintence)	
		for b in all(unbuilt) do
			b[3]-=1
			if(b[3]==0)then
				bld=buildings[b[1]]
				sbox=b[2]
				s=bld[2]
				w=bld[3]
				h=bld[4]
				add_map(s,sbox.l/8,sbox.t/8,w,h)
				add_resources(bld[6],maintence)
				add(built,{b[1],b[2]})
				del(unbuilt,b)
			end
		end
    end

	function draw_build_box()
		if(game_mode !=1) return
		x=mouse.x+cam.x
		y=mouse.y+cam.y
		if(selected_building>0 or selected_road>0)then
			if(selected_building>0)then
				b=buildings[selected_building]
				sbox=box(flr(x/8)*8,flr(y/8)*8,b[3]*8-1,b[4]*8-1)
				w=b[3] h=b[4] s=b[2] r=b[5]
				if(mouse.wu) selected_building=min(#buildings,selected_building+1)
				if(mouse.wd) selected_building=max(1,selected_building-1)
				selected_road=0
			elseif(selected_road>0)then
				b=roads[selected_road]
				sbox=box(flr(x/8)*8,flr(y/8)*8,7,7)
				w=1 h=1 s=b[6] r=b[2]
				if(mouse.wu) selected_road=min(#roads,selected_road+1)
				if(mouse.wd) selected_road=max(1,selected_road-1)
				selected_building=0
			end
			c=7
			if(not col_free_box(sbox,1) or not col_free_box(sbox,1) or not can_afford(r)) c=8
			draw_box(add_box(box(-1,-1,2,2),sbox),c)
			i=0
			for i=0,w-1,1 do
				for j=0,h-1,1 do
					spr(s+i+16*j,sbox.l+i*8,sbox.t+j*8)
				end
			end
			if(mouse.rp and c==7) sfx(2) build(sbox)
			
		elseif(selected_building==0 and selected_road==0)then
			dbox=box(flr(x/8)*8,flr(y/8)*8,8,8)
			c=4
			if(band(0b11,fget(mget(dbox.l/8,dbox.t/8)))!=0)then
				if(band(0b100,fget(mget(dbox.l/8,dbox.t/8)))!=0) return
				c=7
				for b in all(built) do
					if is_in_box(x,y,b[2])then
						draw_box(add_box(b[2],box(0,0,0,1)))
						if(mouse.r)then sfx(1) destroy(1,b) end
						return
					end
				end
				for b in all(built_roads) do
					bx=box(b[2],b[3],8,8)
					if is_in_box(x,y,bx)then
						draw_box(bx)
						if(mouse.r)then sfx(1) destroy(2,b) end
						return
					end
				end
				draw_box(box(dbox.l-1,dbox.t-1,9,9),c)
				if(mouse.r)then sfx(1) destroy(0,dbox) end
			end
		end
	end

-->8 roads

	roads={
		{"chemin de terre",{0,0,0,0,0,0,0},{0,0,0,0,0,0,0},16,16,18},

	}
	built_roads={}

	function add_road(x,y)
		r1={selected_road,x,y,0b00}
		i=0
		for r2 in all(built_roads) do
			if(r2[2]==r1[2]+8 and r2[3]==r1[3])then r1[4]=bor(0b01,r1[4])
			elseif(r2[2]==r1[2]-8 and r2[3]==r1[3])then r2[4]=bor(0b01,r2[4])  end
			if(r2[3]==r1[3]+8 and r2[2]==r1[2])then r1[4]=bor(0b10,r1[4])
			elseif(r2[3]==r1[3]-8 and r2[2]==r1[2])then r2[4]=bor(0b10,r2[4])  end
			i+=1
		end
		add(built_roads,r1)
	end

	function destroy_road(r1)
		for r2 in all(built_roads) do
			if(r2[2]==r1[2]+8 and r2[3]==r1[3])then r1[4]=band(0b10,r1[4])
			elseif(r2[2]==r1[2]-8 and r2[3]==r1[3])then r2[4]=band(0b10,r2[4]) end
			if(r2[3]==r1[3]+8 and r2[2]==r1[2])then r1[4]=band(0b01,r1[4])
			elseif(r2[3]==r1[3]-8 and r2[2]==r1[2])then r2[4]=band(0b01,r2[4]) end
		end
		del(built_roads,r1)
	end

	function draw_roads()
		cbox=box(cam.x,cam.y,127,127)
		for r in all(built_roads) do
			if(is_in_box(r[2],r[3],cbox))then
				rd=roads[r[1]]
				if(band(0b01,r[4])!=0)then
					sspr(rd[4],rd[5],2,8,r[2]+7,r[3]-1)
				end
				if(band(0b10,r[4])!=0)then
					sspr(rd[4],rd[5],8,2,r[2]-1,r[3]+7)
				end
			end
		end
	end

-->8 dialogs

	rnd_dialogs={

		"bonjour monsieur le maire !",
		"comment allez-vous ?",
		"il fait beau aujourd'hui. je devrais peut-etre aller nager.",
		"j'ai tue ma grand-mere aujourd'hui.",
		"desole pas le temps de discuter.",
		"valbonne c'est trop bien.",
		"on mange sub ce midi ? oh... trop tot ?"

	}

__gfx__
00777000193246d8000000000000100000000000000000000011110000088000000000000a910000000aa100004444000077b000055555500007700000000000
07777700cabe976800010000000171000007700000000000017777100008800000000000a419100000a4491000066000b07bbb0057768885007aaa0090094004
077777000000000000171000001766100007700000000000177777710008800000000000a91910000a499191000660000bbbb3105766888577aaaaa997079094
0777770000000000001771000176610007777770077777701755757100088000770770779119144009499191006666000bb33310566688850aaaa990979aa494
077777000000000000177710176611000777777007777770177777710008800077077077099106600949919106776660033333105888666500aa99009aaa9994
07777700000000000017777101611410011771100111111001177110000000001101101100006766094991910c77ccc000343100058866500a9999909aa99994
0707070000000000001771100010014100077000000000000007100000078000000000000000cccc009119100cccccc000044000005865000990099004444440
00707000000000000001171000000014000110000000000000710000000880000000000000000cc00009910000cccc0000044000000550009000000900000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb557666666111bbbbbbbbbbbbbbbbbb55bbbbbbbbb5555bbbbbbbbbbbb5555bbb31b44b31b4bb31bbbb331bb
b555555bb5ff55fbb444444bbccccccbbbbbbbbb55766666666511b44bbb8e42bbbbb55a555bbbbbb57d7d5bbbbbbbbbb57d7d5b1133b41133441133bb33131b
b555555bb4f9594bb444444bbccccccbb4bbbb4b576655555551514444bbe842bbb55a7a54555bbb57000065bbbbbbbb57000065b3314bb331b4b331b311331b
b557755bbf459ffbb444444bbccccccbb0bbbb0b5666666666666144444b8842b5577a795454555b5d0000d1000000005d0000d1131b44131b4b131b13333131
b557755bb4ff994bb444444bbccccccbb022220b56555555555551444b4b3b42b57a79795454545b571111611111111157111161b1bb44b1bb44b1bb31331331
b555555bb4494f4bb444444bbccccccbb244440b5dddddddddddd1b4444b3342b5a9a9a95454545b15d655105656565615d65510bbbb4bbbbb44bbbb33113311
b555555bbf4494fbb444444bbccccccbc022220b51111111111111b444bb9a42b579a9a95454545bb155110d6dd77d55d155110bbb3bb4bb3b4bbb3b13333111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbc244440cb42bbbbbbbb42b44444ba942b579a9a95454545bb1110016d671051d6111001bb13144b131b4b131b111111b
0055775500f459ff0044444400ccccccc022220cbbbbbbbbbbbbb444444b4442b579a9a55554545bb17015166577656161d0151b3331b433314b3331bb3311bb
00557755004ff99400b4444400bcccccc244440cbbbbbbbb48e2b48787872222b5a9a5599555545bb1d01615555115111170161bb11b44b11b44b11bb311331b
55000000ff00000044000000cc000000c022220cbb4a92bb4442b4878787bbbbb5955ff77ff5555bb17015194494494491d0151bbbbbb4bbbb44bbbb13333131
55000000f900000044000000cc000000c244440cbb4442bb2222bb878787bbbbb55ff777777ff05bb1d01614494494494170161bbb3b44bb3b44bb3b31331331
770000004500000044000000cc000000c022220cbb2222bbbbbbbbb4bb2bbbbbbb0f7227755770bbb1111114944944944111111bb31144b311b4b31133113311
77000000ff00000044000000cc000000c244440cbbbbbbb4dc2bbb49a9a2bbbbbb0f720f700770bbb57d7d5944944944957d7d5b11334b11334b113313333111
550000004900000044000000cc000000c022220cbb4bbbb4442bbb499a92bbbbbb07720f77ff70bb5700006549451449570000653331b433314b3331b111111b
55000000440000004b000000cb000000c244440cb44bbbb2222bbb222222bbbbbb000000000000bb5d0000d1951761545d0000d1b11b44b11bb4b11bbbb445bb
b4b444bb444bb444bbcccbbbcccbbcbcc022220cbbb4bbbbccccccccbbbbb4bbbbb000bbbb444bbb571111610000000057111161bbbbbbbbbbbbbbbbbbbbbbbb
bb44444b44b4bb44bccccccbbcbbbbccc244440bbbb0000000000000000000bbbb07760bb44ff4bb15d655101111111115d65510bbbbbbbbbbbbbbbbbb3bbbbb
b44444444b4bbbb4bccccccccbbbbbbcb022220bbbb2424242424242424242bbb0766650b4ff994bb1551107565656565155110bbbbbbbbbbbbbbbbbb3b3bbbb
44444444bbbbbbbbcccccccccbbbbbbbb244440bbbb2424242424242424242bb0766555044f99994b51100166dd77d555111001bbbbbbbbbbbbbbbbbbbbbbbbb
444444444bbbbbbbcccccccccbbbbbbbb022220bbbb2424242424242424242bb066555004ff99994b567d517d670051d516dd11bbbbbbbbbbbbbbbbbbbbbb3bb
4444444bb4bbb4b4cccccccbccbbbbbcb400004bbbb2424242424242424242bb0655500049999440b57d5d1665701d15517d151bbbbbbbbbbbbbbbbbbbbb3b3b
b44444b4444bbb44bccccccbcbcbbbccb0bbbb0bbbb4202020202020202024bbb055000b49994400b5d6d51555d0151111d6d11bbbbbbbbbbbbbbbbbbbbbbbbb
4b444b4b44b4444bbbbcccbbcbbcccccbbbbbbbbbbb0bbbbccccccccbbbbb0bbbb0000bbb444000bbb1111bbb111111bbb1111bbbbbbbbbbbbbbbbbbbbbbbbbb
555555555555555555555555bbbb8bbb42bbbbbbbbb42bbbbbbbbb42bbbbbbb67fbbbbbbbbbbbbb55bbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999
577777777777777777777775bbb8a8bb667777777776677777777766bbbbbbb6ffbbbbbbbbbbb55a555bbbbbbbbbbbb75bbbbbbb966666666666666666666669
576667777777777667766775bbbb8bbb72bbbbbbbbb42bb6bbbbbb47bbbbb005ff0bbbbbbbb55a7a54555bbbbbbbbb7755bbbbbb966666666666666666666669
576660777777777660766075b8bb3bbb7bbbbbbbdbbbbbbb444bbbb7bbbb0775ff40bbbbb5577a795454555bbbbbb777550bbbbb966666666666666666666669
576660777777777dd07dd0758a8bbb8b7bb75bb4bbbbbbbbb444bbb7bbb07a75ff940bbbb57a79795454545bbbbb77775550bbbb966666666666666666666669
57ddd0777777777777777775b8bbb8a87b76d0bb4b6bb5bb44444bb7bb07a7a5a99420bbb5a979a95454545bbb778777555500bb966666666666666666666669
577777755555555557777775b3bbbb8b7b5d10b44444bbb44444bbb777fffaa5a944220bb5a9a9a95454545bb77887875555500b966666999999999999999999
57777775dddddddd57777775bbbbbb3b7b000b44b4444bb444444bb7fffffa9765555555b579a9a11454545b77788887555555009666669fffffffffffffffff
57666775dddddddd57766775bbbbcbbb7bbbbbbb44444bbb44bbbbb755555556d4477fffb579a9a76454545b77888877555555509666669fccffccffccffccff
57666075d117788d57666675bbbcacbb6bbdbbb4444b44bb4bbbbbb6b0aa9944542fffffb579a1176114545b78888777555555559666669ffffffffffffffff6
57666075d117788d57666605bbbbcbbb42bbbb444bb4b44bbbbbbb42b00094445222000bb579a77666d4545b78788776655555559666669fccffccffccffccfd
57ddd075dddddddd57d66105b8bb3bbb66bbb444444444444bbbbb66bb00007f520000bbb579a7666dd4545b7778776666555555966666955555555555555556
57777775dddddddd577d10758a8bbbdb62bbbb4444444475444bbb46bb06607f500110bbb579a9a6d454545b777776600665555596666695555555555533155d
57777775dd777cdd57777775b8bbbdad7bbbbbb44444476d04b4bbb7bb0776ff511100bbb579a9a6d454545b7776666016666555966666957777775551311556
55555555dd77ccdd55555555b3bbbbdb7bbbbbb4b44445d104444bb7bb0667ff5d5510bbb5a9a9a6d454545b776666011166665596666695755557553313315d
6666666500cccc0066666665bbbbbb3b7bbbb4bb4444400044444bb7bb0777ff5ddd10bbb5a9a9a55554545b6666000111116666966666957577575513331156
ccc77cc1bbbbbbbbccc77cc1bbbbcbbb7bbb444b44b4444446444bb7bb0776d666d500bbb5a9a556d555545bbbbbbbbbbbbbbbbb96666695777777555111155d
cc77cc71bbbbbbbbcc77cc71bbbcacbb7bbb4b44b4444544444b44b7bb0677666d5d10bbb59557600d65555bbbbbbbbbbbbbbbbb96666695757757555b45b556
66666665bbbbbbbb66666665bbbbcbbb7bbb4444bbbb44444bb4b4b7bb0776d666dd10bbb556dd6d76d6115bbbbbbbbbbbbbbbbb96666695755557555bbbb55d
c77cc771bbbbbbbbc77cc771bebb3bbb7bbb44b4bbbbbb4444444bb7bb066766dd5d10bbbb177675565d10bbbbbbbbbbbbbbbbbb999999957777775555555556
77cc77c1bbbbbbbb77cc77c1eaebbb8b6bbbb44bbbbbbbbb4444bbb6bb07776006d500bbbb1d6d54256710bbbbbbbbbbbbbbbbbbfffffff5555556565655555d
66666665bbbbbbbb66666665bebbb8a842bbbbbbbbb42bbbbbbbbb42bbb076d017dd0bbbbb16d544225d10bbbbbbbbbbbbbbbbbbcfccfcc65656566666565656
7cc77cc1bbbbbbbb7cc77cc1b3bbbb8b667777777776677777777766bbb0076016000bbbbb101544225100bbbbbbbbbbbbbbbbbbfffffff66666665656666666
ddddddd1bbbbbbbbddddddd1bbbbbb3b42bbbbbbbbb42bbbbbbbbb42bbbbb000100bbbbbbb000000000000bbbbbbbbbbbbbbbbbbccfccfc65656566666565656
cccccccccccccccc4444444444444444bbbbbbbbbb6666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccc4444444444444b44b444442bb611116bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccc444444444444b4b4b499492b61100116bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccc4444444444444444b444442b61000016bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccc77cc4444444444444444b222222b60000006bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccc7cc7c4444444444b44444bbb42bbb56000065bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccc444444444b4b4444bbb42bbbb566665bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
cccccccccccccccc4444444444444444bbbbbbbbbb5555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b2222222222222bb6ddddd63bb6666666b33b3b7b6ddddd688888888888888888888888811111111111111111111111111111111bbbbbb36bbbb34bbbbbbbb36
b2ddddddddddd2bb6d111d6b3b6ddddd6bbb3bb7b6ddddd68666346666666666666666681ddddddd1dddddddddddddddddddddd1bbffbbbffbbbffbbbbbbbbbb
b2d666ddddddd2bb6d111d6bbb6d551d63666b37b6d111d686ddd666ddd66666688866681dd66ddd1dddddddddddddddddddddd1bf00fbf00fbf00fbbbbbbbbb
b2d6661dddddd2bb6ddddd63b56d550d6b6d56bb76d111d686ddd566ddd56666668666681d6666dd1dddddddddddddddddddddd1baff4baff4baff4bbbbbbbbb
b2d5551dddddd2bb6d111d6bb56d550d6b65dd6376d111d68611156611156666688866681d16615d1ddd6666dddddddd6666ddd1ba994ba994ba994bbbbbbbbb
b2ddddddddddd2bb6d111d6bb06d110d6b66666b76ddddd68666666666666666666666681dd115dd1ddd66665ddddddd66665dd1ba994ba994ba994bbbbbbbbb
b2222222222222bb6ddddd6b3b6ddddd6b11111b76d533d68888888888888888888888881ddddddd1ddd11115ddddddd11115dd1ba994ba994ba994bbbbbbbbb
b6666666666661bb6ddddd67776ddddd6777777776d333d67777777777777777777777701ddddddd1dddddddddddddddddddddd1ba994ba994ba994bbbbbbbbb
b6aa6d66a6dd61bb6d111d67776dd11d6777777776d335d666c7c66ccccc676c7cc66c701dd66ddd1dddddddddddddddddddddd1666666666666666666666666
b6666666666661bb6d111d6bb56d110d6bb77bb776d335d66cc766cccc6667cc7c66cc701dd665dd1dddddddddddddddddddddd16555555555555555555dd556
b6d66d66d66a61bb6ddddd63b56d10dd65ddddd776d333d67777777777777777777777701dd665dd111111111111111111111111655dd55dd55dd55555d00d56
b6666666666661bb6ddddd63b06ddddd65d565d776d533d6c777787766c88888888888881dd115dd178778777878787787788770655dd05dd05dd055551dd056
b6a66aa6d66d61bb6ddddd6bbb6d776d65d776d776d333d6c77788876cc86666666666681ddddddd187787878778788787877870655110511051105555111056
b6666666666661bb6d111d6bb36ddddd65ddddd776d355d6777778777778666666ddd6681ddddddd186688866868686886866860655555555555555555511556
b6dd6d6dd6aa61bb6ddddd63bb6666666111111776ddddd6cc77777776c8666666ddd56811111111178787878778787787788770666666666666666666666666
b6666666666661bb6666666bbb5555555bbbbbb776666666c67555557cc866666611156877777777566666666666666666666660444444444444444444444440
b6a66a66d6dd61bb555555577777777777777777755555557775cc65777866666666666877777777575555577755555575555570447744447444447444447440
b6666666666661bb777777777777777777777777777777777775c6c5777888888888888866666666565cc756665ccc7565cc7560447c4447cc4447cc4447cc40
b6dd6a66dd6a61bb6665666bbbbbb33b6366636776ddddd622256cc5222777777777777077777777575c7c57775c77c575c7c57044cc444ccc444ccc444ccc40
b6666666666661bb63d1d36bb33b3b1163ddd36776ddddd6bbbbbbbbbbb7cc7666c7cc60666666665457cc544457ccc5457cc5404444444cc7444cc7444cc740
b6a6dd66d6aa61bb65d1d36bb1333bbb63d5d36dd6533336bbbbbbbbbbb7c676ccc7c660777777775bbbbbbbbbbbbbbbbbbbbbbb4444444c77444c77444c7740
b6666666666661bb63d0d36b3b11bbbb65d3d56dd6533356bbbbbbbbbbb7777777777770666666665bbbbbbbbbbbbbbbbbbbbbbb440044477c44477c44477c40
b6666600666661bb63d3d3631bb3bb3365d3d36dd6353336bbbbbbbbbbb7777777777770777777775bbbbbbbbbbbbbbbbbbbbbbbff00fffffffffffffffffff0
bddddd00ddddd1bb63d5d36bbbb1133163ddd36dd6333536bbbbbbbbbbb2222222222220444444445bbbbbbbbbbbbbbbbbbbbbbbff00fffffffffffffffffff0
555555555555555563d3d56bb33bb11b63d3d36dd6335336bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
555555555555555565ddd56bb133b3b363d5d56116666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
777777775555555565d3d36bbb11bbb363d5d56116335336bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
755575555555555565d5d363bb3bb33b63ddd36116533536bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
755575557777777763ddd3611b3bbb1b65ddd36116333356bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
75557555755555556335536bb3b3bbbb6553336116355336bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
75557555755555556666666b3b31b3bb6666666006666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7555755575555555555555511bbbb11b5555555005555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
55555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000888888000000000000000
57aaaa99994444444444444500000000000000000000000000000000000000000000000000000000000000000000000000000000888000000888888000000000
55555555555555555555555500000000000000000000000000000000000000000000000000000000000000000000000000000088800000088888888888000000
5a994555a54555444444442500000000000000000000000000000000000000000000000000000000000000000000000000000888000008889888008888800000
5555555aa54555555555555500000000000000000000000000000000000000000000000000000000000000000000000000008880000888999998800088880000
59455aa7a54545544444222500000000000000000000000000000000000000000000000000000000000000000000000000088800088889998889988000888000
54557aaa954545554222222500000000000000000000000000000000000000000000000000000000000000000000000000888000888899000088898800088800
0057a66a954545455555555500000000000000000000000000000000000000000000000000000000000000000000000000888008888000000000088880008800
315a610695454545d5d6560b00000000000000000000000000000000000000000000000000000000000000000000000000880088880000aaaaaa008888000880
b05a600695454545dd5dd50b000000000000000000000000000000000000000000000000000000000000000000000000088808888000aaa00000a00888800080
b157d6609545454556d6d50b00000000000000000000000000000000000000000000000000000000000000000000000008800898000aa000aaaa000088800080
b15add1095454545d562060b000000000000000000000000000000000000000000000000000000000000000000000000088089800a0a00aa000aaa0008880008
b05a9d1a954545450002000b00000000000000000000000000000000000000000000000000000000000000000000000008888980a0aa0a0000000aa009880008
bb5a9a9a95454545bbbb65bb00000000000000000000000000000000000000000000000000000000000000000000000008889880a0a00000000a00a009988008
3b579a9a95454545bbb5bbbb00000000000000000000000000000000000000000000000000000000000000000000000008889800a0a000000000a0aa00998008
bb579a9a954545453bbb5bbb00000000000000000000000000000000000000000000000000000000000000000000000080899800a0a000000000a00a00998808
b3579a9a55554545b3bbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb5a9a5599555545bbb66bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b59552676625555bb6116bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb5527646746d205bb6006bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb024444442220bbb5665b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b04674662d620bbbb55bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b304d465062d20bb3bbbb3b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb000005000000b3b3bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
bb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bccccccccccccccccbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3b13333111133331111333311113
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bb111111bb111111bb1
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb445bbbbb445bbbbb445bbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbb
bbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbccccccccccccccccb311331bb311331bb311331bb311331bb311331bb311331bb311331bb311331bbb
bbbbbbbbbbbbbbbbbbbbbbb3b3bbbbb3b3bbbbb3b3bbbbcccccccccccccccc1333313113333131133331311333313113333131133331311333313113333131b3
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccc3133133131331331313313313133133131331331313313313133133131331331bb
bbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbcccc77cccccccccc3311331133113311331133113311331133113311331133113311331133113311bb
bbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbb3b3bbbbb3b3bccc7cc7ccccccccc1333311113333111133331111333311113333111133331111333311113333111bb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccb111111bb111111bb111111bb111111bb111111bb111111bb111111bb111111bbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbb
3311bbbbbbbbbbbbbbbbbbbbbbbbbbbb3311bbbb3311bbccccccccccccccccbb3311bbbb3311bbbb3311bbbb3311bbbbb000bbbb3311bbbbbbbbbbbbbbbbbbbb
11331bbb3bbbbbbb3bbbbbbb3bbbbbb311331bb311331bccccccccccccccccb311331bb311331bb311331bb311331bbb07760bb311331bbb3bbbbbbbbbbbbbbb
333131b3b3bbbbb3b3bbbbb3b3bbbb1333313113333131cccccccccccccccc13333131133331311333313113333131b076665013333131b3b3bbbbbbbbbbbbbb
331331bbbbbbbbbbbbbbbbbbbbbbbb3133133131331331cccccccccccccccc313313313133133131331331313313310766555031331331bbbbbbbbbbbbbbbbbb
113311bbbbb3bbbbbbb3bbbbbbb3bb3311331133113311cccccccccccc77cc331133113311331133113311331133110665550033113311bbbbb3bbbbbbbbbbbb
333111bbbb3b3bbbbb3b3bbbbb3b3b1333311113333111ccccccccccc7cc7c133331111333311113333111133331110655500013333111bbbb3b3bbbbbbbbbbb
11111bbbbbbbbbbbbbbbbbbbbbbbbbb111111bb111111bccccccccccccccccb111111bb111111bb111111bb111111bb055000bb111111bbbbbbbbbbbbbbbbbbb
b445bbbbbbbbbbbbbbbbbbbbbbbbbbbbb445bbbbb445bbccccccccccccccccbbb445bbbbb445bbbbb445bbbbb445bbbb0000bbbbb445bbbbbbbbbbbbbbbbbbbb
3311bbbb3311bbbb3311bbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
11331bb311331bb311331bbb3bbbbbbbbbbbbbbbbbbbbbccccccccccccccccbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb
3331311333313113333131b3b3bbbbbbbbbbbbbbbbbbbbccccccccccccccccb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbbbbbbbbbbbbbbbbbb3
3313313133133131331331bbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
1133113311331133113311bbbbb3bbbbbbbbbbbbbbbbbbcccccccccccc77ccbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbb
3331111333311113333111bbbb3b3bbbbbbbbbbbbbbbbbccccccccccc7cc7cbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbbbbbbbbbbbbbbbb
11111bb111111bb111111bbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b445bbbbb445bbbbb445bbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3311bbbbb000bbbb444bbbbbb000bbbb3311bbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3311bbbb3311bbbb3311bbbb
11331bbb07760bb44ff4bbbb07760bb311331bbb3bbbbbccccccccccccccccbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbb311331bb311331bb311331bb3
333131b0766650b4ff994bb076665013333131b3b3bbbbccccccccccccccccb3b3bbbbb3b3bbbbbbbbbbbbbbbbbbbbb3b3bbbb13333131133331311333313113
3313310766555044f999940766555031331331bbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb31331331313313313133133131
113311066555004ff999940665550033113311bbbbb3bbccccccccccccccccbbbbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bb33113311331133113311331133
33311106555000499994400655500013333111bbbb3b3bccccccccccccccccbbbb3b3bbbbb3b3bbbbbbbbbbbbbbbbbbbbb3b3b13333111133331111333311113
11111bb055000b49994400b055000bb111111bbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bb111111bb111111bb1
b445bbbb0000bbb444000bbb0000bbbbb445bbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb445bbbbb445bbbbb445bbbb
3311bbbb3311bbbb3311bbbbbbbbbbbbbbbbbbbb3311bbbb3311bbccccccccccccccccbb3311bbbbbbbbbbbbbbbbbbbbbbbbbbbb3311bbbb3311bbbb3311bbbb
11331bb311331bb311331bbb3bbbbbbb3bbbbbb311331bb311331bccccccccccccccccb311331bbb3bbbbbbbbbbbbbbb3bbbbbb311331bb311331bb311331bb3
3331311333313113333131b3b3bbbbb3b3bbbb1333313113333131cccccccccccccccc13333131b3b3bbbbbbbbbbbbb3b3bbbb13333131133331311333313113
3313313133133131331331bbbbbbbbbbbbbbbb3133133131331331cccccccccccccccc31331331bbbbbbbbbbbbbbbbbbbbbbbb31331331313313313133133131
1133113311331133113311bbbbb3bbbbbbb3bb3311331133113311cccccccccccccccc33113311bbbbb3bbbbbbbbbbbbbbb3bb33113311331133113311331133
3331111333311113333111bbbb3b3bbbbb3b3b1333311113333111cccccccccccccccc13333111bbbb3b3bbbbbbbbbbbbb3b3b13333111133331111333311113
11111bb111111bb111111bbbbbbbbbbbbbbbbbb111111bb111111bccccccccccccccccb111111bbbbbbbbbbbbbbbbbbbbbbbbbb111111bb111111bb111111bb1
b445bbbbb445bbbbb445bbbbbbbbbbbbbbbbbbbbb445bbbbb445bbccccccccccccccccbbb445bbbbbbbbbbbbbbbbbbbbbbbbbbbbb445bbbbb445bbbbb445bbbb
3311bbbb3311bbbb3311bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbb3311bbbb3311bbbb3311bbbb3311bbbbb000bbbb444bbbbb
11331bb311331bb311331bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbb3bbbbbb311331bb311331bb311331bb311331bbb07760bb44ff4bbb3
3331311333313113333131bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccb3b3bbbb13333131133331311333313113333131b0766650b4ff994b13
3313313133133131331331bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbb313313313133133131331331313313310766555044f9999431
1133113311331133113311bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbb3bb33113311331133113311331133113311066555004ff9999433
3331111333311113333111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbb3b3b13333111133331111333311113333111065550004999944013
11111bb111111bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbb111111bb111111bb111111bb111111bb055000b49994400b1
b445bbbbb445bbbbb445bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbb445bbbbb445bbbbb445bbbbb445bbbb0000bbb444000bbb
3311bbbb3311bbbb3311bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbbbbbbbbbb
11331bb311331bb311331bbb3bbbbbbb3bbbbbbbbbbbbbbbbbbbbbccccccccccccccccbb3bbbbbb311331bb311331bb311331bb311331bb311331bbb3bbbbbbb
3331311333313113333131b3b3bbbbb3b3bbbbbbbbbbbbbbbbbbbbccccccccccccccccb3b3bbbb1333313113333131133331311333313113333131b3b3bbbbbb
3313313133133131331331bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbb3133133131331331313313313133133131331331bbbbbbbbbb
1133113311331133113311bbbbb3bbbbbbb3bbbbbbbbbbbbbbbbbbcccc77ccccccccccbbbbb3bb3311331133113311331133113311331133113311bbbbb3bbbb
3331111333311113333111bbbb3b3bbbbb3b3bbbbbbbbbbbbbbbbbccc7cc7cccccccccbbbb3b3b1333311113333111133331111333311113333111bbbb3b3bbb
11111bb111111bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbb111111bb111111bb111111bb111111bb111111bbbbbbbbbbb
b445bbbbb445bbbbb445bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbbbbbbbbbb
bbbbbbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3bbbbbb311331bb311331bb311331bb311331bb311331bb311331bccccccccccccccccbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbbbbb
b3bbbb133331311333313113333131133331311333313113333131ccccccccccccccccb3b3bbbbbbbbbbbbbbbbbbbbb3b3bbbbb3b3bbbbb3b3bbbbbbbbbbbbbb
bbbbbb313313313133133131331331313313313133133131331331ccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb3bb331133113311331133113311331133113311331133113311cccccccccccc77ccbbbbb3bbbbbbbbbbbbbbbbbbbbbbb3bbbbbbb3bbbbbbb3bbbbbbbbbbbb
bb3b3b133331111333311113333111133331111333311113333111ccccccccccc7cc7cbbbb3b3bbbbbbbbbbbbbbbbbbbbb3b3bbbbb3b3bbbbb3b3bbbbbbbbbbb
bbbbbbb111111bb111111bb111111bb111111bb111111bb111111bccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbb3311bbbb3311bbbb3311bbbbbbbbbbbbbbbbbbbb3311bbccccccccccccccccbbbbbbbbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbbbbbbbbbb
3bbbbbb311331bb311331bb311331bbb3bbbbbbb3bbbbbb311331bccccccccccccccccbb3bbbbbb311331bb311331bb311331bb311331bb311331bbb3bbbbbbb
b3bbbb133331311333313113333131b3b3bbbbb3b3bbbb13333131ccccccccccccccccb3b3bbbb1333313113333131133331311333313113333131b3b3bbbbbb
bbbbbb313313313133133131331331bbbbbbbbbbbbbbbb31331331ccccccccccccccccbbbbbbbb3133133131331331313313313133133131331331bbbbbbbbbb
bbb3bb331133113311331133113311bbbbb3bbbbbbb3bb33113311ccccccccccccccccbbbbb3bb3311331133113311331133113311331133113311bbbbb3bbbb
bb3b3b133331111333311113333111bbbb3b3bbbbb3b3b13333111ccccccccccccccccbbbb3b3b1333311113333111133331111333311113333111bbbb3b3bbb
bbbbbbb111111bb111111bb111111bbbbbbbbbbbbbbbbbb111111bccccccccccccccccbbbbbbbbb111111bb111111bb111111bb111111bb111111bbbbbbbbbbb
bbbbbbbbb445bbbbb445bbbbb445bbbbbbbbbbbbbbbbbbbbb445bbccccccccccccccccbbbbbbbbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbbbbbbbbbb
3311bbbb3311bbbb3311bbbb3311bbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbbb
11331bb311331bb311331bb311331bbb3bbbbbbbbbbbbbbbbbbbbbccccccccccccccccbb3bbbbbb311331bb311331bb311331bb311331bb311331bb311331bb3
333131133331311333313113333131b3b3bbbbbbbbbbbbbbbbbbbbccccccccccccccccb3b3bbbb13333131133331311333313113333131133331311333313113
331331313313313133133131331331bbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbb31331331313313313133133131331331313313313133133131
113311331133113311331133113311bbbbb3bbbbbbbbbbbbbbbbbbccccccccccccccccbbbbb3bb33113311331133113311331133113311331133113311331133
333111133331111333311113333111bbbb3b3bbbbbbbbbbbbbbbbbccccccccccccccccbbbb3b3b13333111133331111333311113333111133331111333311113
11111bb111111bb111111bb111111bbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbb111111bb111111bb111111bb111111bb111111bb111111bb1
b445bbbbb445bbbbb445bbbbb445bbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbbb
bbbbbbbbbbbbbbbbbbbbbbbbb000bbbbb000bbbb3311bbbb3311bbccccccccccccccccbb3311bbbb3311bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3311bbbb
3bbbbbbbbbbbbbbb3bbbbbbb07760bbb07760bb311331bb311331bccccccccccccccccb311331bb311331bbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbb311331bbb
b3bbbbbbbbbbbbb3b3bbbbb0766650b07666501333313113333131cccccccccccccccc1333313113333131bbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbb13333131b0
bbbbbbbbbbbbbbbbbbbbbb07665550076655503133133131331331cccccccccccccccc3133133131331331bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3133133107
bbb3bbbbbbbbbbbbbbb3bb06655500066555003311331133113311cccccccccccccccc3311331133113311bbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3311331106
bb3b3bbbbbbbbbbbbb3b3b06555000065550001333311113333111cccccccccccccccc1333311113333111bbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3b1333311106
bbbbbbbbbbbbbbbbbbbbbbb055000bb055000bb111111bb111111bccccccccccccccccb111111bb111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bb0
bbbbbbbbbbbbbbbbbbbbbbbb0000bbbb0000bbbbb445bbbbb445bbccccccccccccccccbbb445bbbbb445bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb445bbbb
bbbbbbbbbbbbbbbb3311bbbb3311bbbb3311bbbb3311bbbb3311bbccccccccccccccccbb3311bbbbbbbbbbbbbbbbbbbbbbbbbbbb3311bbbb444bbbbbb000bbbb
bbbbbbbb3bbbbbb311331bb311331bb311331bb311331bb311331bccccccccccccccccb311331bbb3bbbbbbb3bbbbbbb3bbbbbb311331bb44ff4bbbb07760bb3
bbbbbbb3b3bbbb1333313113333131133331311333313113333131cccccccccccccccc13333131b3b3bbbbb3b3bbbbb3b3bbbb13333131b4ff994bb076665013
bbbbbbbbbbbbbb3133133131331331313313313133133131331331cccccccccccccccc31331331bbbbbbbbbbbbbbbbbbbbbbbb3133133144f999940766555031
bbbbbbbbbbb3bb3311331133113311331133113311331133113311cccccccccccccccc33113311bbbbb3bbbbbbb3bbbbbbb3bb3311888888f999940665550033
bbbbbbbbbb3b3b1333311113333111133331111333311113333111cccccccccccccccc13333111bbbb3b3bbbbb3b3bbbbb3b3b18883111498888880655500013
bbbbbbbbbbbbbbb111111bb111111bb111111bb111111bb111111bccccccccccccccccb111111bbbbbbbbbbbbbbbbbbbbbbbb88811111b888888888885000bb1
bbbbbbbbbbbbbbbbb445bbbbb445bbbbb445bbbbb445bbbbb445bbccccccccccccccccbbb445bbbbbbbbbbbbbbbbbbbbbbbb888bb4458889888008888800bbbb
3311bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbb888bbbb8889999988bbb8888bbbbb
11331bbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbccccccccccccccccbb3bbbbbbb3bbbbbbbbbbbbbbb3b888bbb88889998889988bb3888bbbb
333131b3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbccccccccccccccccb3b3bbbbb3b3bbbbbbbbbbbbb3b888bbb888899bb3b8889883b3888bb3
331331bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbb888bb8888bbbbbbbbbb8888bbb88bbb
113311bbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbbbbbb3bbcccccccccccc77ccbbbbb3bbbbbbb3bbbbbbbbbbbbb883b8888bb3baaaaaa3b8888bb388bb
333111bbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bbbbb3b3bccccccccccc7cc7cbbbb3b3bbbbb3b3bbbbbbbbbbb888b8888bb3aaabbbb3a3b88883b38bb
11111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbb88bb898bbbaabbbaaaabbbb888bbb8bb
b445bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbb88b898bbababbaabbbaaabbb888bbb8b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb4bbbbccccccccccccccccbbbbb4bbbbbbbbbbbbbbbbbbbb888898babaababbbbbbbaabb988bbb8b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbbbbb000000000000000000000000000bbbbbbbbbbbbbbbbbbbb888988bababbbbbbbbabbabb9988bb8b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbbbbb242424242424242424242424242bbbbbbbbbbbbbbbbbbb388898bbababbbbbbbbbabaabb998bb8b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb242424242424242424242424242bbbbbbbbbbbbbbbbbbb8b8998bbababbbbbbbbbabbabb9988b8b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbbb242424242424242424242424242bbbbbbbbbbbbbbbbbbb8b8899bbabbabbbbbbbbbababb8998b8b
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbbbbbbbbbbb242424242424242424242424242bbbbbbbbbbbbbbbbbbb8bb899bbaababbbbbbbbbababb89888bb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb420202020202020202020202024bbbbbbbbbbbbbbbbbbb8bb8899bbabbabbbbbbbbabab889888bb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0bbbbccccccccccccccccbbbbb0bbbbbbbbbbbbbbbbbbb8bbb889bbaabbbbbbbabaabab898888bb
bbbbbbbbbbbbbbbbbbbbbbbb3311bbbb3311bbbb3311bbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbb3311bbb8331888bbbaaabbbaa31ababb898188bb
bbbbbbbbbbbbbbbb3bbbbbb311331bb311331bb311331bbbbbbbbbccccccccccccccccbb3bbbbbbbbbbbbbb311331bb38133888b3bbaaaa311aa1bb8983388b3
bbbbbbbbbbbbbbb3b3bbbb133331311333313113333131bbbbbbbbccccccccccccccccb3b3bbbbbbbbbbbb133331311383318888b3abbb13aaa1318888388813
bbbbbbbbbbbbbbbbbbbbbb313313313133133131331331bbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbb3133133131881338888bbaaaaaa313388883188131
bbbbbbbbbbbbbbbbbbb3bb331133113311331133113311bbbbbbbbcccc77ccccccccccbbbbb3bbbbbbbbbb33113311331883118888b3bb331133888811888133
bbbbbbbbbbbbbbbbbb3b3b133331111333311113333111bbbbbbbbccc7cc7cccccccccbbbb3b3bbbbbbbbb1333311113388811b889888b133998888333888113
bbbbbbbbbbbbbbbbbbbbbbb111111bb111111bb111111bbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbb111111bb111888bbb88998889998888b118881bb1
bbbbbbbbbbbbbbbbbbbbbbbbb445bbbbb445bbbbb445bbbbbbbbbbccccccccccccccccbbbbbbbbbbbbbbbbbbb445bbbbb448888bbb8899999888bbbb8885bbbb
bbbbbbbb3311bbbb3311bbbbb000bbbb3311bbbb3311bbbb3311bbccccccccccccccccbb3311bbbb3311bbbb3311bbbb331188888bb8889888bbbbb888bbbbbb
3bbbbbb311331bb311331bbb07760bb311331bb311331bb311331bccccccccccccccccb311331bb311331bb311331bb311331888888888883bbbbb888bbbbbbb
b3bbbb1333313113333131b0766650133331311333313113333131cccccccccccccccc13333131133331311333313113333131b3888888b3b3bb8883b3bbbbb3
bbbbbb313313313133133107665550313313313133133131331331cccccccccccccccc31331331313313313133133131331331bbbbbbbb888888bbbbbbbbbbbb
bbb3bb331133113311331106655500331133113311331133113311cccccccccccccccc33113311331133113311331133113311bbbbb3bbbbbbb3bbbbbbb3bbbb

__gff__
0000808000000202000000000000000083838300000101010101010101010101000000000001010101010101010101010000000000000000010101010100000001010100050505010101010101010101010101000504050101010101010101010100010005050501010101000001010105050000050100000000000000000000
01010101010101010101010101010100010101010101010101010101010101010101010101010001010100000001010100000101010100000000000000000000010101000c0266000c02660000000000010101000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000
__map__
2f3f3e3f3f3f3e3f2f2f2f2f2f2f2f2f2f2f2f3f3e3e3f3f3f3f3f3f2f2f2f3f3e3f3f3f2f2f39382f3f2f2f2f3f3e3e3f3f2f2f2f2f2f2f3e3e3e3f3f3f3e3f2f2f2f3f3e63633e5370703f3f3f3f3f2f2f2f2f2f3f3f3f3f3e3e3e3e3f3f3f3f3f3f2f2f2f2f2f2f2f2f2f3f3e3e3e3f3f3f3f3f2f2f2f2f2f2f2f2f2f3f3f
2f3f3f3f3f3f3f3f2f2f2f2f2f2f3f3e3e3f3f2f2f2f2f2f2f2f2f2f3f3f2f2f2f2f3f3e3e3f2f3f3e3e3f2f2f2f2f2f2f2f2f2f2f2f2f433f3f2f392f3f3e3e3f2f3f3e3e5363533f71702f2f2f2f2f2f2f2f3f3e633f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f3f3e3f2f2f38392f3f3f3f2f2f2f2f2f2f3938382f2f3f3f2f2f
2f2f2f2f3f3e3e3f3f2f2f2f2f2f2f2f2f2f3f3f2f2f2f2f2f38383f3e3f2f2f3838382f3f3f3f3f3e3f3e3e3e3f3f3f3f3f3f3f3f3e3e3f2f2f2f3f3e3e3f2f2f38382f3f3f3f632f70712f632f2f632f3f3e53632f38382f3f2f2f38392f2f3f3f3f3f3f3f3f3f3f2f2f2f382f3f3e3e3e2f3f3e3e3f2f2f2f3f3e3e3e3e3f
3e3e3f3f2f2f2f2f3f3f3e3e3f2f2f2f2f3f3e3e3f2f3f3e3e3f2f2f3f3f2f3f3f3f2f2f2f2f2f3e3e532f2f2f2f2f3f3f3f3f432f382f2f3f3f3f3f3f2f2f382f2f2f2f2f2f3f3e3e70713f63633f63633e3e3f2f3f3f433e3e2f2f2f2f3f433e5343633f3f532f2f2f2f2f2f2f3f3f2f2f392f3f3e3e3f2f2f2f2f2f3f2f2f
2f2f2f3f3f2f2f2f3f3e3e3f3f3f3f3f3f3f3f2f38392f2f3f3f2f392f3f3f3e3e3f2f2f2f2f3f3f3e3e3f3f2f2f2f2f2f3f3e3e3f2f2f2f3f3e3f3f3f3e3e3e3e3f2f2f3839382f5370703f3f3e533f2f2f2f2f2f3e3e3f3f2f39382f3f633e633f3e3f3f3f3f433f3f3f3e3e3e3e3e3e3f3f3f3f3f3f3f3f3f3f3f3f2f2f2f
3f3f3f3f3f3f3f3f2f2f2f2f3f3f3e3e3e3e3e3f3f2f2f2f2f2f2f3f3e3e3e3f2f2f2f2f2f3f3f3e3e3e2f2f2f3f3e53433e533e3f2f38382f3f43382f3f3e3e3e3f2f2f2f2f3f432f2f70702f3f3e3f2f2f432f2f3f533f2f2f2f2f2f3f3e432f2f2f2f3f3f3e3e3f3f3e3e3f3f3f2f2f3f2f2f2f2f2f3f3e3e3f2f2f2f3f3f
3f3e3f2f2f2f2f3f2f2f2f3f3f3f2f2f2f2f2f2f2f3f3e3e3e3e3e3e3f3f2f2f2f2f2f2f2f3f3e3f2f2f2f382f2f3f43433e3e2f2f2f2f3f3e3e3f2f382f3f3e3e3f2f2f2f2f6363636370703f2f2f2f2f38392f3f3e3e3e2f2f2f2f2f533e533e3f2f3f6363633f3f2f2f2f2f2f2f2f2f2f2f2f3f3f3e3e3f2f2f2f2f2f3f3d
3f3f3f3e3e3e3e3e3f2f2f3f3f3f2f2f2f2f2f2f2f3f3e3e3e3e3f2f2f2f3f3e3e3e3f3f2f2f2f38382f3f2f2f2f3f3e3e3f2f2f2f3f3f2f3f2f2f2f2f2f3f3f2f382f2f2f2f3f3f433e71703f2f2f2f2f2f3f3e533f2f2f2f2f39382f3f633e3f2f2f2f2f2f2f2f2f2f2f3f3f3e3f2f2f2f2f2f3f3e3f3f2f2f3f7331743173
2f38382f3f3e3e3f3f2f3f3f3f2f2f2f2f2f2f2f38382f3f3f3f2f2f382f2f3f3e3e3e3f2f2f2f2f3f3e3e3f2f3f53533e3e3e3f3e3e3f2f2f3f3e633e3f432f2f2f3f3f2f2f2f2f2f2f70713f3e3e3f63636353432f2f2f2f2f2f3f3e3e3f432f2f2f2f2f39382f2f2f3e3e3e3e3f2f2f2f2f2f2f2f3f3e3e3e73312f307355
2f2f2f2f3f3e3e3e3f3f3e3f2f2f2f3f3e3e3f2f2f382f2f2f2f3f3f2f2f2f3f3e3e3f3f2f2f3f3e3e3f2f2f2f3e533f2f2f2f2f3f3f3f2f2f3f3e3e63633e2f2f2f3f3f2f2f2f3f532f70703f2f2f632f2f3f633e3e433e3f2f2f2f3f2f2f2f3f3e533e3f2f2f2f2f3f3f3e3f3f2f2f2f2f2f2f2f38392f3f313f2f2f2f3073
2f2f3f3e3e3f3f2f392f2f3f2f2f3f3e3e3f3f2f2f2f2f2f2f2f3f3e3f3f3f3f3f3e3e3e3f3f3f3f3f2f2f2f3f3f3f2f2f2f3f3f3f2f2f2f382f2f3f3e3e3f3f2f382f2f2f2f2f3f3e3e70703f2f2f2f2f2f2f2f3f3e43533f2f2f2f2f2f2f2f3f3f3f3f3e3e3e3e3e3f3f3e3e2f2f2f3f3e3e3f2f2f382f2f2f2f3f3e3e3f3f
2f2f3f3e3e3f3f2f2f2f2f2f2f2f2f2f2f2f3f3e3e3e3f2f2f2f2f3f3f3f3f3f2f2f2f2f2f3f2f2f2f3f3e3e3f432f2f3f3e3e3e3f2f2f2f2f2f2f63633e3f2f2f2f2f3f3e3f38382f2f70702f2f633e3e3f2f38382f3f433f3f3e3f3f2f2f2f2f2f2f3f533e3f532f392f3f3f3f3f3e3e3f3f2f3f2f2f2f2f2f2f3f3e3f3f2f
382f3f3f3f3f3f3f3f3f3e3e3f3f3f2f2f3f3f3e3e3f3f3f3f3f3f2f2f2f2f2f2f2f382f3f3f3e3f3f2f2f2f2f2f3f3f3e3e2f2f2f2f2f2f2f3f3e633f2f38392f2f3f3e3f2f2f2f2f2f70702f3f3f3f2f39382f38382f2f2f2f2f2f5363633f3f2f2f433f3f532f2f2f2f3f3e3e3e3f3f2f382f3f3e3e3f2f2f3f3f3e3e3f2f
3f3e3e3f2f2f2f2f3f3e3e3f3f3f3f3f3f2f2f2f2f2f3f3e3e3e3e3e3e3f3f3e3f2f2f2f2f2f2f2f2f2f2f2f3f3f3f2f2f2f2f2f3f533f2f2f3f3e3e3e3f2f2f2f2f2f2f3f3f533f3f3f70713f3f6353633f3f3f2f382f3f3f43533f3e3e3e3e633f2f2f2f3f2f2f2f2f38382f2f2f2f2f2f3f3f3f2f2f2f2f2f3e3e3f3f3f2f
3e3e3e3e3e3e3f3f3f2f3f3f2f2f2f2f2f2f2f2f3f3e3e3f2f2f2f2f2f2f3f3f3e3e3f2f2f3f3f2f2f2f3f3e3e3e3f2f2f2f2f633e632f3f3f633e3e3f2f2f3f3f3e3e43533e63437635363637767663633e633e3e3f2f2f533e533e533f2f3f3e3f2f2f2f3f3e3e3f2f2f3f3f2f382f3f3e3e3e3f2f2f2f2f2f3f2f2f2f2f3f
2f2f2f2f2f2f2f2f2f2f2f3f3f2f2f2f2f2f3f3e3e3f2f2f382f3f3f2f2f2f2f2f2f2f2f2f3f3e3f2f533f3f632f2f2f2f2f2f2f2f2f2f2f433e3f2f2f38382f433f3e3e3e3f2f2f2f7671703f762f2f3f2f2f2f2f2f2f2f3f533e3f2f38382f2f2f2f433f3f2f2f2f2f2f3e3e3f3f3e3e3f2f2f2f3f3f3f2f392f3f3f3f3f3f
39382f2f2f3f3f3f2f2f2f3e3f2f2f2f2f2f3f3f2f2f2f2f2f3f3f3f3f3f3f3e3f3f3f2f2f3f2f2f3f3f3e3e633f2f2f3f3f3e633f2f2f3f3f433f2f2f2f2f2f3f3e3e3f2f43382f2f2f70702f2f2f2f3f3f3f3f3f2f2f2f3f532f2f2f2f3f3f2f2f2f3f3e3f2f2f2f2f3f3f3e3e3e3f2f3f3f3f3f3f3e3e3e3f2f2f3f3f2f38
2f2f2f3f3e3e3e3f2f2f2f2f2f2f3f3f3e3e3f3f3f3f3f3f2f2f2f2f2f2f3f3f3e3e3e3f2f2f2f2f3f3e3e3e633e3f3f2f2f2f2f2f2f3f3e3e3e3f2f2f2f2f2f3f63632f3f3f633e3f4370703f3e3e3f3f2f2f3f2f392f2f3f433f3f3f3f3e3e533f2f2f432f2f2f2f3f3e3e3e3f2f382f3f3e3e3e3f2f2f2f2f382f3f3f3f2f
2f2f2f3f3f3f2f2f2f2f382f3f3f3f2f2f2f2f2f3f3f3e3e3f3f2f2f2f2f3f3e3e3e3f3f2f2f2f2f2f2f2f433f633e3e3e3f2f2f2f2f3f3e633e3f3f2f2f2f3f3e632f2f3f3e63533e3f70713f2f3f533f2f2f382f2f3f3e3e535353533e533e3f2f3f3f3f3f2f2f2f3f3f3f3f2f2f2f3f3e3e3f3e3e3e2f2f2f3f3f3e3e3f2f
317472733f3e3f2f2f2f3f3f3e3e3f2f3f2f2f392f3f3f3e3e3f2f2f2f2f3f3f3f3f3e3e3f2f2f2f2f2f532f3f3e3e3e3e532f2f2f3f3f53533f2f2f2f2f2f3f3f632f2f53633e3e633f70712f2f2f633e3e3f2f2f2f2f2f2f533e433e3e3f2f38433f433e3f2f2f3f3f2f2f2f3f3e3f2f2f2f2f3f3e3e3f3f3f3e3e3f3e3e3f
733031382f3f3f3f3f3f3f2f2f2f2f3f3e3e3f3f3e3e3e2f2f2f3f3e3e3f2f2f382f3f3e3e3f3e3e3f3f2f3f3f6363432f2f2f2f2f3f3e633f2f2f2f3f3f2f2f3f3f2f2f4343532f392f3f707063633f2f2f2f2f3f3f3f2f2f382f2f2f2f2f2f3f433e3f2f2f2f2f3f3e3f2f2f3f3f2f2f3f3f3e3e3e2f2f2f2f2f2f2f3f3e3e
72312f3f3f2f392f3f3e3f2f2f2f2f2f3f3f2f2f2f2f2f2f2f2f3f3f2f2f392f2f2f2f3f3f2f38382f2f2f3f3e633e3f53533f3f3f3f2f2f3f3f3e3e3e3f2f2f3f3e3e3f2f434353433e6370703f3e3f2f632f3f3e633e3e3e3e3f3f432f2f2f3f3f2f38382f2f2f3f3f3f3f2f2f2f2f2f3e3e3f2f2f382f3f3f3f3f3e3e3e3f
77773f3e3e3e3f3f3f3f3f2f2f2f2f2f2f3f3f3f3f3f3f3e3e3f2f2f2f2f2f2f2f3f3e3e3e3e3f2f2f2f2f3f3f2f3f3f3f3f3f3f3f3f2f2f3f3f3f3f2f2f2f2f2f2f2f2f2f2f3f3e3e3f2f2f70702f2f3f3f3e633f2f632f63632f3f633e3e3f2f2f3f3f3f3e3f2f2f3f3e3f2f2f2f2f3f3f3f2f2f392f3f3f3f3f3f3f2f2f39
3f3f2f2f3f3f3e3e3e3f2f2f3f3e3e3f3f3e3e3e3f3f3f3e3e3f3f3f3f2f2f2f2f3f3f3f3f3e3f2f2f3f533f632f63633e3f2f2f2f2f2f2f2f2f2f2f2f2f2f3f3f3f3f3f2f2f3f3f2f382f2f70712f3f3e6363633839632f2f2f3f63632f2f2f2f2f633e533f632f2f3f3e3f2f2f2f3f3e3e3e3e3f2f2f2f2f2f2f2f2f383838
2f2f2f2f3f3e3e3f2f38392f2f2f3f3e3e3e3f2f2f382f3f3f3f3f3f3e3e3f3f2f2f2f2f3f3e3f2f2f3f3f3f3f633f3f2f2f3f3f3e3e632f2f2f3f3e4363633f63533f433f2f2f2f2f2f3e3e70703f3e3f2f2f2f2f2f392f3f433e633f2f2f2f2f2f3f633e3e3f3f3f3f3f3f2f2f2f3f3e3e3e3e3e3f3f3e3e3f3e3e3f2f2f2f
3f3f2f2f3f3f2f2f2f2f2f3f3f3f3f3f3f2f382f2f2f2f2f2f2f2f2f2f3e3e3f2f2f2f2f3f3f3e3e3f3f2f2f2f3f3e632f2f3f3e533e533e3f2f2f3f633e3e3f2f2f3f3e3f2f2f3f3f3e533e717039382f2f633e3e3f633e3e3f2f2f2f2f38392f3f3f3f2f2f2f2f2f2f2f2f2f3f3e3e3f3f3f3f3f3f2f2f2f2f2f3f3f3f3e3e
3f2f2f2f2f3f3f3f3f3f3f3f3f3e3e3f3f2f2f3f3e3f2f2f3f3f3e3f3f3f3f2f2f2f2f3f3f3e3e3e2f2f2f2f2f3f3e3e43433f2f2f2f3f3f2f2f2f3f633e3f3f2f2f2f3f3f3f3f3f3f3f3f3e70712f2f2f3f3f3e3f633f3f532f2f3f3f3f2f3f3e3e3e632f2f2f3f3e3e3f2f2f2f3f3e3f2f2f2f2f2f2f382f2f2f2f2f2f3f3f
2f3f3e3e3f3f3e3e3f3f2f2f2f3f3e3e3f2f2f3f3f3f2f2f2f3f3f3e3e3f2f2f2f2f2f3f3e3f2f2f2f2f2f2f382f2f3f3f3f3f2f2f2f533e3e3f3f3f2f2f3f3f632f2f633e3e3f2f2f2f2f2f70702f2f2f2f632f2f2f63633e533f633e532f2f2f3f633f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f3f3e3f2f2f2f3f3e3e3f3f3f
2f3f3f3f3f3f3f3f3f3f3f3e3f3f3f3f3f3f3f2f3839382f2f3f3e3e3e3f2f2f2f2f3f3f3f2f2f2f2f3f3e3e2f2f2f2f2f2f2f2f2f2f533e633f2f2f2f2f3f3e3f2f2f2f534343433e633e3f70702f3f3e3e3f3f633f3f433e3e3f3f3f3e3f2f2f2f3f432f2f2f2f2f3f3e3e3e3f2f3f3f3f3f3f3f3e3e3f2f2f2f2f2f2f2f3f
2f3f3e3e3f2f2f2f2f2f2f2f2f2f2f3f3e3e3e3e3f2f2f2f2f3f3f3f3e3e3e2f2f2f3f3e3e3f3e3e3f3e3e3e3f3f3e3e3e3f3f3f3f3f3f3f2f2f382f3f533f632f2f2f2f2f432f2f3f3e3e537570702f2f2f3f3f3f3f3f533f2f38383f633e3f2f2f2f2f2f2f2f2f3e3e3f3f2f392f3f3e3e3e3e3f2f2f2f3f3f3f3f2f2f382f
3f3f3f3f3f3e3e3f3f3f3f3f2f2f2f3f3f3f3f3f3f2f2f2f3f3f2f382f3f3f3f2f2f3f3f2f2f3f3f3e3e3f2f2f2f2f2f2f2f3f3f3f3f2f382f2f433f3f633f3f3f3e3e3f3f3f2f2f2f2f2f3f3e71703f2f2f2f2f2f2f2f433f3f3f3f3e3e3f2f3f3f3f3f3f2f2f2f3f3f2f3f3f3f3e3e3f2f2f3f3f2f2f2f3f3e3e3f2f2f3f3f
3f2f2f38382f3f3f3e3e3e3e3f3f2f2f2f2f2f3f3e3f2f2f3f3e3f2f2f2f2f392f2f3f2f2f3f3e3e3f2f2f39382f2f2f3f3f2f2f39382f2f3f3e3f532f532f3f3e3e3e433f3f3f3f2f2f2f3f3e70713e3f2f2f2f2f2f2f2f3f3e3e533f2f39382f2f3f3f2f2f2f2f2f2f2f3f3e3e3f2f2f39382f2f2f3f3e3e3f2f2f2f2f3f3e
__sfx__
01010000000002750000000203001a3401a3401a510070002c300273002d30029300243001b4001a4000000000000000000000000000334000000000000354000000019400224001740010400000000000000000
0005000000000186301b64019640146300f6300f6300b6300b6200762007620046100161001610046100261001610086000860007600295002740027400270002700027000260002600000000000000000000000
00060202176171b6571c6471a63717627126270f6270b6270661704617036170361716617196571b6471b6371962715627116270c617076170461703617206171a6571b6471763714627116270d6270a61708617
011e001f0065100651006510065100651006510065100651006510065100651006510065100651006510065100651006510065100651006510064100641006410064100641006410064100641006410064100641
011e00211511115111151111511118111181111c1111c111131111311115111151111511115111181111811115111151111a1111a1111a1111a11115111151111c1111c111131111311115111151111811118111
011e00212103521035210352303521035210352603524035210351f03521035000052103523035210352603524035210352303521035000052103523035210352603524035260352403521035230352603500005
011e00211d0301d0301f0301a0301c03000100180301a0301c0301a030210301f0301d0301c0301a0301c0301a03000130180401c0700010023070210701a070180701a0701807021070230701a0700010000100
017800000c8410c8410c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c8400c84018841188401884018840188401884018840188402483124830248302483024830248302483024830
01780000269542694026930185351870007525075240752507534000002495424940249301d5241d7000c5250c5242952500000000002b525000001d5241d5250a5440a5450a5440a5201a7341a7350a0350a024
017800000072400735007440075500744007350072400715007340072500000057440575505744057350572405735057440575503744037350372403735037440375503744037350372403735037440373503704
017800000a0041f734219442194224a5424a5224a45265351a5341a5350000026934269421ba541ba501ba550c5340c5450c5540c555000001f9541f9501f955225251f5341f52522a2022a3222a452b7342b725
__music__
03 05044444
02 06044344

