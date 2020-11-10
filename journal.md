JOURNAL DE BORD
===


12 avril
---

Brainstorming :  
Plusieurs concepts nous ont semblés intéressants. L’idée d’un city builder nous semble séduisante, ainsi que l’idée de suivre l’histoire de Valbonne et de Sophia-Antipolis.  
Il nous faut recréer une forêt ainsi que des bâtiments propres à la région pour pouvoir coller parfaitement au thème.  
On pense mettre en place des missions ou quêtes pour rendre le jeu plus vivant. Par exemple un PNJ (personnage non joueur) pourrait demander au joueur de lui construire une maison.  


Personnages :  
Par soucis de simplicité pour le début, nos personnages sont des fantômes (création des premières sprites).  
L’affichage des personnages est bon, avec des couleurs de base et d’yeux aléatoires, permettant une grande diversité et d’éviter un sentiment de répétition.  
Le joueur peut se déplacer mais il n’y a encore aucune collision avec les PNJ.  


13 avril
---

Menus :  
Les menus s’affichent correctement et permettent d’afficher des textes.  
Il y a un menu pour afficher les ressources, un second pour afficher les futurs dialogues et un dernier qui servira de menu principal depuis lequel le joueur pourra créer ou détruire des bâtiments.  


Sprites :  
Nous avons créé deux sprites pour le curseur de la souris : un classique (identique à celui de Pico-8) et un pour la construction.  


Interface :  
Nous avons implémenté la prise en compte de la souris et les différents curseurs imaginés.  


14 avril
---

Ressources :  
Nous avons défini les différentes ressources du joueur : Or, Technologie, Environnement, Sécurité, Prospérité et Score.  
Les sprites des ressources ont été dessinées et intégrées au menu. Le rendu nous plaît beaucoup.  


Collisions :  
Le système de collision avec les PNJ fonctionne correctement. Cependant notre algorithme semble pouvoir être largement optimisé. La console ayant peu de ressources il faudra probablement l’améliorer plus tard dans le développement.  


15 avril
---

Sprites :  
La première sprite de bâtiment que nous avons est une maison. Nous espérons réussir les futurs bâtiments aussi bien que celui-ci.  
Nous avons implémenté les sprites pour l’herbe, les arbres et les rochers, qui ont eux aussi un bon rendu. Il reste encore beaucoup de travail sur les sprites au vu de la quantité de bâtiments que nous avons imaginés durant le brainstorming.  


16 avril
---

Map :  
L’affichage de la carte est fonctionnel, pour l’instant il n’y a que de l’herbe mais plus tard nous ajouterons une forêt ainsi qu’une rivière pour coller à la topologie du lieu.  


Collisions :  
Le système de collision permet maintenant également de détecter les collisions statiques avec les éléments de la map. Les personnages ne peuvent par exemple plus se déplacer sur une case avec un arbre ou un rocher.  


Sprites :  
Nous avons ajouté les sprites de l’infirmerie et de la caserne. Pour la caserne nous avons dû nous inspirer de pixel-arts trouvés un peu partout sur internet afin d’avoir des exemples (il s’agit d’une de nos premières sprites complexes).  


17 avril
---

Menus :  
Les menus peuvent maintenant avoir du texte et des boutons cliquables. On peut également cacher les menus afin de décharger l’écran d’informations.  
L’affichage de messages dans la boîte de dialogue devra être amélioré pour voir le texte défiler, à la manière des premiers Pokémon.  


Sprites :  
Nous avons ajoutés des sprites de routes, très optimisées dans la spritesheet : pour regrouper tous les cas de croisement, il faudrait normalement plus d’une quinzaine de sprites, mais nous avons trouvé une solution n’en nécessitant que quatre.  
Nous avons également intégré les sprites des menus (ressources, dialogue…).  


Debug :  
La découverte de la fonction stat() nous a révélé que notre système de collision est à optimiser de toute urgence. 400 Ko de RAM sont utilisés sur les 2 Mo de la console simplement avec 50 PNJ et le joueur. Le CPU lui est a 60% d’utilisation.  
Les menus aussi sont à optimiser ils prennent 300 Ko dans la RAM et utilisent 30% du CPU.  


18 avril
---

Menus :  
Nous avons commencé à repenser nos menus afin de décharger la RAM, mais il faudra probablement tout recommencer de zéro tant les changements à faire sont importants.  


Bâtiments :  
Le système de construction est opérationnel. Afin de détecter si une case est disponible nous réutilisons le système de collision. Par conséquent la construction sera optimisée en même temps que les collisions.  
Du côté de la RAM nous pouvons encore faire des efforts, 200 Ko pour 100 maisons.  


Sprites :  
Nous avons ajouté de nouveaux sprites : celui d’un nouveau bâtiment, les vignes, ainsi que d’autres décoratives telles que les fleurs.  


19 avril
---

Collisions :  
Les optimisations faites ont été très largement rentables. Nous n’utilisons plus que 1.5% du CPU quelque soit le nombre de PNJ et la RAM est elle aussi beaucoup moins surchargée avec seulement 60 Ko pour ces 100 mêmes PNJ.  


Rendu :  
Nous avons implémenté l’occlusion culling sur la carte et les PNJ, ce qui nous fait gagner une dizaine de pourcents sur l’utilisation du CPU et sur les appels systèmes de la console.  


Sprites :  
Le moulin est enfin terminé. Il a prit un temps considérable à être fait, mais le résultat en vaut la peine.


20 avril
---

Optimisations :  
Le travail sur les menus à été efficace, l’utilisation de la RAM a été réduit au plus bas et le CPU est beaucoup moins surchargé qu’avant.  
Globalement les différentes optimisations que nous avons fait ont permi d’améliorer drastiquement les performances.


Bâtiments :  
La destruction des bâtiments et du terrain est opérationnelle.  
Nous avons ajouté un indicateur pour montrer au joueur la disponibilité de la case, ou si il y a quelque chose à détruire.


Sprites :  
Des sprites diverses ont été ajoutées afin de casser la monotonie de la carte : eau, terre, ponts (vertical et horizontal), panneau… Nous avons également créé une sprite pour notre logo en jeu, qui sera affiché dans le menu de départ.


21 avril
---

Routes :  
Les routes sont un élément essentiel à tout city builder qui se respecte. Nos routes sont opérationnelles. Leur affichage pourrait être plus performant.  
Bien que nous ayons un système de routes fonctionnel nous n’avons pas vraiment réfléchi à leur intérêt pour le gameplay. L’idée viendra probablement plus tard.  
Les sprites créées au début du concours ne nous ont finalement pas tous servis puisque nous avons trouvé une solution n’utilisant plus que deux sprites.  


Sprites :  
Il y a eu besoin d’une refonte des sprites des routes. Celui de l’église a également été ajouté, ainsi que celui du marché (qui fut assez difficile à réaliser, étonnamment).


22 avril
---

Menus :  
Nous avons amélioré la navigation dans le menu principal. Il y a désormais un sous-menu pour le mode construction. Le prix du bâtiment et son apport mensuel sont maintenant correctement affichés.  
Il y a également une liste pour recenser tous les bâtiments construits par le joueur.


Construction :  
Les bâtiments ne se construisent plus instantanément, il leur faut une durée définie pour être construit. En attendant il y a un chantier à la place.  
Un sprite de chantier à donc été ajouté : il est adapté afin de pouvoir être utilisé pour des bâtiments de n’importe quelle taille (2x2, 2x3, 2x4, 3x3, 3x4, 4x4…).


23 avril
---

Journée de repos...


24 avril
---

Ecran titre :  
L’écran titre est opérationnel, un clic fait apparaître un menu duquel on peut lancer on peut lancer une partie ou changer l’apparence du personnage.  
La caméra se déplace tout le long de la carte.


Temps :  
Le temps s’écoule désormais du premier janvier 1519 (création de Valbonne) jusqu’en 2019.  
Le jeu est séparé en deux phases, équivalentes en durée de jeu. La première, de 1519 à 1969, présente des bâtiments médiévaux tandis que la seconde voit l’apparition de bâtiments plus récents comme les hôpitaux ou des bâtiments de l’université de Sophia-Antipolis tels que Polytech.


Sprites :  
Les premiers bâtiments modernes ont été ajoutés : immeuble, place de parking (utilisable peut-être à l’avenir) et hôpital.


25 avril
---

Musiques :  
Nous avons enfin notre musique. Elle est un peu répétitive mais elle permet tout de même de combler le vide sonore qu’il y avait avant.


Gameplay :  
Nous avons commencé à équilibrer le jeu. Les vitesses de jeu ont été modifiées pour être plus cohérentes et les prix des bâtiments ont été ajustés. Il reste cependant des améliorations afin d’avoir le jeu le plus agréable possible.

Sprites :  
La sprite de Polytech a été implémentée. Elle a demandé du temps, mais nous sommes satisfait du résultat.


26 avril
---

Bugs :  
La quasi totalité des bugs que nous avions ont été corrigés. Il ne reste plus que quelques détails mineurs à régler.


Gameplay :  
Une seconde phase d’équilibrage a eu lieu. Nous avons décidé de quelques modifications sur les prix des bâtiments.  
Un bâtiment acheté plusieurs fois verra son prix augmenter.  
Si la sécurité devient trop basse, un bâtiment peut être détruit pour cause de vandalisme.


Sprites :  
Les derniers bâtiments modernes sont implémentés : l’école, le poste de police, le supermarché et l’usine. Ce fut une longue journée ! Heureusement, les bâtiments modernes nécessitent moins de détails.


27 avril
---

Construction :  
Nous avons ajouté de nombreux bâtiments afin de rajouter du contenu.  
Leur prix n’a pour l’instant été que improvisé, il faudra refaire une session d’équilibrage pour les ajuster.


Gameplay :  
Une quête servant de didacticiel a été ajoutée. Un PNJ explique au joueur comment créer une maison et le joueur reçoit une récompense à la fin de la mission.  
Nous n’avons malheureusement pas assez de temps pour mettre en place autant de quêtes et d’évènements qu’on le souhaitait. La manière dont nous avons géré le projet ne rend pas cela dramatique, le jeu est déjà amusant sans tous ces évènements.


Sprites :  
Nous avons ajouté un nouveau sprite, celui de la taverne.


28 avril
---

Menu :  
Nous avons modifié l’affichage de certains éléments pour améliorer la lisibilité.  
Un élément auquel nous n’avons pas fait attention est la liste des bâtiments. Au fur et à mesure que le jeu avance, la diversité des bâtiments construits augmente, et la liste ne permet pas de les faire défiler. Le temps manque et le problème restera en état. Nous le corrigerons probablement après le concours.


Documentation :  
Jusqu’à présent nous n’avions pas réfléchi au nom de notre jeu. Après quelques réflexions nous avons décidé de le baptiser SimSophia 500, en référence au jeu SimCity 3000.  
La description du jeu a été faite et le journal de bord mis en forme, il ne reste plus qu’à envoyer !


1er mai
---

Nous avons été surpris de recevoir un mail nous informant que le dernier délai était finalement le 1er mai, le soir à minuit, et non le 28 avril au soir comme il avait été annoncé. Nous en avons donc profité de ce delai supplémentaire pour corriger certains bugs graphiques que nous avions repérés ainsi que quelques optimisations de gameplay.  

Nous avons également fait la vidéo et mis à jour les fichiers de documentation comme demandé. Pour le HTML, nous avons quelques soucis avec la prise en compte de la molette de la souris ; nous y avons donc renoncé, cet élément étant essentiel pour notre gamplay.
