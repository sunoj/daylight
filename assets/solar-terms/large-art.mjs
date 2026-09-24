/** Independent 64-unit illustration masters. Normalize only at export.
 * Contours, interior engraving and translucent washes are separate layers.
 */
const line = (d, width = 1.4, opacity = 1) => ({ d, mode: 'stroke', width, opacity });
const wash = (d, opacity = .10) => ({ d, mode: 'fill', width: 0, opacity });
const dot = (x,y,r=.65) => wash(ellipse(x,y,r,r),.7);
const warm = shapes => shapes.map(shape => ({...shape, tone: 'warm'}));
const cool = shapes => shapes.map(shape => ({...shape, tone: 'cool'}));
function ellipse(x,y,rx,ry) {
  const k=.552285;
  return `M ${x-rx} ${y} C ${x-rx} ${y-ry*k} ${x-rx*k} ${y-ry} ${x} ${y-ry} C ${x+rx*k} ${y-ry} ${x+rx} ${y-ry*k} ${x+rx} ${y} C ${x+rx} ${y+ry*k} ${x+rx*k} ${y+ry} ${x} ${y+ry} C ${x-rx*k} ${y+ry} ${x-rx} ${y+ry*k} ${x-rx} ${y} Z`;
}
function leaf(x,y,tx,ty,w,veins=2) {
  const dx=tx-x,dy=ty-y,len=Math.hypot(dx,dy),nx=-dy/len,ny=dx/len;
  const p=(t,o=0)=>`${x+dx*t+nx*o} ${y+dy*t+ny*o}`;
  // Evaluate the actual outline and midrib curves so vein tips stay inside the leaf.
  const sample=(t,a,b)=>{
    const q=1-t;
    return [3*q*q*t*a[0]+3*q*t*t*b[0]+t*t*t,3*q*q*t*a[1]+3*q*t*t*b[1]];
  };
  const mid=t=>sample(t,[.26,w*.27],[.70,w*.23]);
  const vein=(t,end)=>{
    const start=mid(t),target=[end[0],end[1]*.88];
    const c1=[start[0]+(target[0]-start[0])*.2,start[1]+(target[1]-start[1])*.55];
    const c2=[start[0]+(target[0]-start[0])*.7,start[1]+(target[1]-start[1])*.9];
    return ` M ${p(...start)} C ${p(...c1)} ${p(...c2)} ${p(...target)}`;
  };
  const upper=`M ${p(0)} C ${p(.13,w*.86)} ${p(.55,w*1.02)} ${p(1)}`;
  const lower=`M ${p(1)} C ${p(.68,-w*.42)} ${p(.28,-w*.64)} ${p(0)}`;
  const shade=`M ${p(0)} C ${p(.26,w*.27)} ${p(.70,w*.23)} ${p(1)} C ${p(.68,-w*.42)} ${p(.28,-w*.64)} ${p(0)} Z`;
  const midrib=`M ${p(0)} C ${p(.26,w*.27)} ${p(.70,w*.23)} ${p(.96)}`;
  let ribs='';
  for(let i=0;i<veins;i++) {
    const t=.14+i*.48/Math.max(veins-1,1);
    ribs+=vein(t,sample(t+.20,[.13,w*.86],[.55,w*1.02]));
    ribs+=vein(t+.08,sample(t+.25,[.28,-w*.64],[.68,-w*.42]));
  }
  const shapes=[wash(shade,.13),line(upper,1.25),line(lower,.95,.85),line(midrib,.82,.8)];
  if(ribs) shapes.push(line(ribs,.64,.62));
  return shapes;
}
function droplet(x,y,r) {
  const body=`M ${x} ${y-r*1.45} C ${x-r*.18} ${y-r*.62} ${x-r} ${y+r*.02} ${x-r} ${y+r*.5} C ${x-r} ${y+r*1.67} ${x+r} ${y+r*1.67} ${x+r} ${y+r*.5} C ${x+r} ${y+r*.02} ${x+r*.18} ${y-r*.62} ${x} ${y-r*1.45} Z`;
  const shade=`M ${x+r*.35} ${y-r*.3} C ${x+r*.75} ${y+r*.44} ${x+r*.36} ${y+r*1.12} ${x-r*.47} ${y+r*.96} C ${x+r*.67} ${y+r*1.56} ${x+r*1.18} ${y+r*.63} ${x+r*.35} ${y-r*.3} Z`;
  const paths=[wash(body,.10),wash(shade,.19),line(body,1.05,.96)];
  // Omit sub-pixel glints on small drops; reserve a quiet reflection for larger dew.
  if(r>=2.5) paths.push(line(`M ${x-r*.46} ${y+r*.1} C ${x-r*.64} ${y+r*.45} ${x-r*.45} ${y+r*.7} ${x-r*.28} ${y+r*.75}`,.6,.45));
  return cool(paths);
}
function cloud() {
  const canopy='M 14 27 C 7 27 6 20 11 17 C 13 16 15 16 17 16 C 19 8 30 7 35 14 C 41 10 49 13 51 20 C 58 19 61 27 54 30';
  return cool([
    wash('M 14 27 C 7 27 6 20 11 17 C 13 16 15 16 17 16 C 19 8 30 7 35 14 C 41 10 49 13 51 20 C 58 19 61 27 54 30 C 42 31 25 27 14 27 Z',.055),
    line(canopy,1.2),line('M 14 27 C 20 27 22 28 25 28 M 42 30 C 46 30 50 31 54 30',.8,.72),
    line('M 21 17 C 24 12 30 13 32 18 M 39 21 C 42 18 48 20 48 23',.65,.46),
    wash('M 10 23 C 15 27 20 23 24 25 C 33 29 45 25 55 28 C 52 30 44 32 36 29 C 25 26 14 30 10 23 Z',.07),
  ]);
}
function sun(x,y,r,rays=true) {
  const edge=ellipse(x,y,r,r);
  const crescent=`M ${x-r*.5} ${y+r*.78} C ${x+r*.6} ${y+r*.95} ${x+r*.95} ${y-r*.15} ${x+r*.7} ${y-r*.7} C ${x+r*1.2} ${y+r*.3} ${x+r*.3} ${y+r*1.16} ${x-r*.5} ${y+r*.78} Z`;
  const paths=[wash(edge,.045),wash(crescent,.14),line(edge,1.2)];
  if(rays) for(let i=0;i<12;i++) {
    const a=i*Math.PI/6,from=r+3.5,to=from+(i%3===0?3:1.8);
    paths.push(line(`M ${x+Math.cos(a)*from} ${y+Math.sin(a)*from} L ${x+Math.cos(a)*to} ${y+Math.sin(a)*to}`,.85,.6));
  }
  return warm(paths);
}
function snow(x,y,r,branches=true) {
  let spokes='',branchesPath='',facets='';
  for(let i=0;i<6;i++) {
    const a=i*Math.PI/3-Math.PI/2,dx=Math.cos(a),dy=Math.sin(a);
    const p=(t,o=0)=>`${x+dx*t-dy*o} ${y+dy*t+dx*o}`;
    spokes+=` M ${p(r>10?r*.17:0)} L ${p(r)}`;
    if(branches) branchesPath+=` M ${p(r*.81,-r*.19)} L ${p(r*.59)} L ${p(r*.81,r*.19)}`;
    if(r>10) {
      facets+=` M ${p(r*.28)} L ${p(r*.43,-r*.085)} L ${p(r*.59)} L ${p(r*.43,r*.085)} Z`;
      branchesPath+=` M ${p(r*.97,-r*.09)} L ${p(r*.82)} L ${p(r*.97,r*.09)}`;
    }
  }
  const shapes=[line(spokes,r>10?1.05:.95,.95),line(branchesPath,.85,.8)];
  if(r>10) shapes.push(wash(facets,.10),line(facets,.65,.6));
  return cool(shapes.filter(shape=>shape.d));
}
function blossom(x,y,r=6,rotation=0) {
  let petals='',folds='',shadow='';
  // Unequal petal lengths and shallow notches prevent a pinwheel-like center.
  for(let i=0;i<5;i++) {
    const a=i*Math.PI*2/5-Math.PI/2+rotation;
    const length=r*[1,.92,1.04,.94,.98][i];
    const p=(t,o)=>`${x+Math.cos(a)*t-Math.sin(a)*o} ${y+Math.sin(a)*t+Math.cos(a)*o}`;
    petals+=` M ${p(2,-.55)} C ${p(length*.65,-length*.64)} ${p(length*1.05,-length*.44)} ${p(length,-.4)} C ${p(length*.91,.1)} ${p(length*.94,.2)} ${p(length,.6)} C ${p(length*.94,length*.54)} ${p(length*.49,length*.52)} ${p(2,.65)}`;
    if(i===1 || i===3) shadow+=` M ${p(2,.65)} C ${p(length*.4,length*.12)} ${p(length*.75,length*.16)} ${p(length,.6)} C ${p(length*.94,length*.54)} ${p(length*.49,length*.52)} ${p(2,.65)} Z`;
    if(i%2===0) folds+=` M ${p(2.8,.4)} C ${p(length*.4,length*.12)} ${p(length*.6,length*.19)} ${p(length*.73,length*.17)}`;
  }
  let stamens='';
  for(let i=0;i<5;i++) {
    const a=i*1.256+rotation;
    stamens+=` M ${x+Math.cos(a)} ${y+Math.sin(a)} L ${x+Math.cos(a)*2.5} ${y+Math.sin(a)*2.5}`;
  }
  return [wash(petals,.045),...cool([wash(shadow,.13)]),line(petals,1.05),line(folds,.6,.44),...warm([line(stamens,.75,.95),dot(x,y,.65)])];
}
const ripple = (x,y,rx) => cool([
  line(`M ${x-rx} ${y} C ${x-rx*.9} ${y+2.8} ${x+rx*.75} ${y+3.1} ${x+rx} ${y+.25}`,.8,.6),
  line(`M ${x-rx*.72} ${y-.8} C ${x-rx*.43} ${y-1.7} ${x-rx*.12} ${y-1.6} ${x+rx*.1} ${y-1.3}`,.6,.32),
]);
function blade(x,y,tx,ty,bend=4) {
  const dx=tx-x,dy=ty-y;
  const edge=`M ${x} ${y} C ${x+dx*.12-bend} ${y+dy*.45} ${tx-dx*.22} ${ty-dy*.12} ${tx} ${ty} C ${tx-dx*.35} ${ty-dy*.3} ${x+dx*.24+2} ${y+dy*.35} ${x} ${y} Z`;
  return [wash(edge,.09),line(edge,1.15,.9),line(`M ${x} ${y} C ${x+dx*.2} ${y+dy*.5} ${tx-dx*.2} ${ty-dy*.15} ${tx} ${ty}`,.65,.4)];
}
function ear(x,y,tilt=0,awns=false) {
  const shapes=[line(`M ${x} ${y+36} C ${x+tilt*.4} ${y+23} ${x+tilt*.8} ${y+8} ${x+tilt} ${y}`,1.15)];
  for(let i=0;i<4;i++) {
    const cy=y+5+i*6.5,cx=x+tilt*(1-(5+i*6.5)/36);
    for(const side of [-1,1]) {
      const yy=cy+(side>0?1.9:0),span=5.2+i*.32;
      const edge=`M ${cx} ${yy+4} C ${cx+side*3} ${yy+4.3} ${cx+side*(span+1.2)} ${yy+.5} ${cx+side*span} ${yy-2} C ${cx+side*2.1} ${yy-2.7} ${cx+side*.3} ${yy+.1} ${cx} ${yy+4} Z`;
      shapes.push(wash(edge,.13),line(edge,1.0),line(`M ${cx+side*1.4} ${yy+2.3} C ${cx+side*2.5} ${yy+.3} ${cx+side*3.6} ${yy-.4} ${cx+side*(span-.8)} ${yy-.7}`,.6,.6));
      if(awns) shapes.push(line(`M ${cx+side*span} ${yy-2} C ${cx+side*(span+1)} ${yy-4} ${cx+side*(span+2)} ${yy-7} ${cx+side*(span+2.4)} ${yy-9}`,.7,.65));
    }
  }
  return shapes;
}
const maple = 'M 20 48 C 17 44 13 43 11 39 C 14 40 16 38 17 37 C 13 34 11 30 9 26 C 13 28 17 29 21 29 C 21 25 19 20 20 17 C 24 20 27 22 30 23 C 33 18 36 12 38 8 C 38 14 41 20 42 25 C 46 25 50 23 53 22 C 52 27 49 31 48 34 C 50 35 54 36 56 36 C 52 40 47 42 44 45 C 44 47 45 50 44 51 C 40 51 34 48 31 48 C 28 49 24 49 20 48 Z';

const masters = {
  '立春': [
    line('M 31 55 C 30 45 33 33 35 22',1.5),
    ...leaf(32,40,12,24,9,3),...leaf(34,30,53,10,9,3),
    ...leaf(31,48,46,35,5,1),
    line('M 15 56 C 22 53 40 53 49 56 M 21 59 C 29 58 36 58 42 59',.9,.45),
    ...sun(15,12,3,false),
  ],
  '雨水': [
    ...cloud(),
    ...droplet(19,37,2),...droplet(33,33,2.5),...droplet(46,39,1.7),
    ...ripple(30,50,18),...ripple(30,56,24),
    ...cool([line('M 18 44 L 18 46 M 45 45 L 45 47',.65,.4)]),
  ],
  '惊蛰': [
    ...warm([line('M 46 6 L 39 16 L 45 16 L 38 27',1.2,.85)]),
    ...cool([wash('M 22 29 C 17 31 16 41 19 47 C 22 54 30 54 33 47 C 36 40 34 31 30 29 Z',.10),wash('M 29 32 C 32 38 31 47 27 50 C 34 49 37 37 29 32 Z',.11)]),
    line('M 22 29 C 17 31 16 41 19 47 C 22 54 30 54 33 47 C 36 40 34 31 30 29',1.25),
    line('M 21 28 C 20 20 32 19 32 28 C 29 30 24 30 21 28 Z M 26.5 30 C 25.5 37 25.8 45 26 50',1.1),
    line('M 23 22 C 23 18 19 16 17 17 M 29 22 C 30 18 33 17 34 18',.85),
    line('M 19 34 C 15 33 13 31 11 31 L 8 34 M 18 40 C 14 39 11 40 10 42 L 8 46 M 20 47 C 15 47 14 51 14 55 M 34 34 C 37 32 39 31 41 32 M 35 40 C 38 40 41 41 42 44 M 33 47 C 37 49 38 52 37 55',.95),
    line('M 22 33 C 20 36 20 43 23 47 M 30 33 C 32 38 32 42 29 47',.65,.55),
    dot(22.3,24,.5),dot(30,24,.5),
    ...blade(46,56,55,34,1),line('M 8 58 C 17 56 22 58 29 57 M 34 57 C 41 55 48 58 55 56',.7,.4),
  ],
  '春分': [
    // Separate trailing feather edges from the body: no intersecting wing stripes.
    wash('M 30 29 C 20 26 11 15 7 7 C 8 19 13 31 25 35 L 15 54 L 29 43 L 32 55 L 35 36 C 43 37 51 44 57 47 C 53 36 47 28 40 27 C 42 22 38 20 35 23 C 34 25 33 27 30 29 Z',.065),
    line('M 30 29 C 20 26 11 15 7 7 C 8 18 11 26 16 30 L 16 27 C 19 32 22 34 25 35 L 15 54 L 29 43 L 32 55 L 35 36 C 39 36 42 39 45 41 L 44 38 C 49 43 53 45 57 47 C 53 36 47 28 40 27 C 42 22 38 20 35 23 C 34 25 33 27 30 29',1.25),
    line('M 12 18 C 16 25 22 28 28 30 M 18 25 C 21 29 25 31 27 31 M 38 31 C 44 32 49 38 53 42 M 37 33 C 42 34 45 37 48 40 M 29 37 C 26 42 22 47 19 49 M 32 38 L 32 47',.7,.65),
    ...cool([wash('M 31 30 C 33 28 35 27 39 27 C 38 31 35 34 32 35 C 32 33 32 32 31 30 Z',.2),line('M 34 29 C 35 30 36 30 37 29',.6,.6)]),
    ...warm([line('M 40 24 L 44 25 L 40 26',.85)]),dot(37.5,24,.6),
    line('M 8 40 C 11 42 15 42 18 40 M 44 52 C 49 54 54 53 57 51',.7,.38),
  ],
  '清明': [
    line('M 7 9 C 20 3 42 8 57 18',1.8),
    line('M 19 6.6 C 21 23 17 39 10 54 M 34 8.2 C 39 27 31 45 28 58 M 48 12.7 C 53 25 49 37 45 46',1.15),
    ...leaf(19,22,11,14,3,0),...leaf(18,31,26,21,3,0),...leaf(16,40,9,32,3,0),...leaf(13,48,20,39,3,0),
    ...leaf(36,25,28,17,3,0),...leaf(35,35,43,25,3,0),...leaf(32,46,25,37,3,0),...leaf(49,31,56,23,2.8,0),...leaf(47,41,41,33,2.8,0),
    ...droplet(45,50,1.25),
  ],
  '谷雨': [
    line('M 31 55 C 30 41 31 36 31 30 M 30 51 C 25 45 21 43 16 40',1.65),
    ...leaf(31,43,47,27,6,2),...leaf(31,36,20,24,5,2),...blade(30,53,15,34,5),...blade(32,54,51,42,-1),
    ...droplet(10,16,1.6),...droplet(32,12,2.1),...droplet(51,17,1.7),
    ...ripple(31,56,22),...ripple(31,59,13),
  ],
  '立夏': [
    // Only visible petal edges are inked, leaving clean overlap boundaries.
    wash('M 8 29 C 15 27 23 32 29 39 C 20 42 12 39 8 29 Z',.07),
    wash('M 56 29 C 49 27 41 32 35 39 C 44 42 52 39 56 29 Z',.06),
    line('M 26 39 C 17 42 10 37 8 29 C 14 28 20 31 23 34 M 38 39 C 47 42 54 37 56 29 C 50 28 44 31 41 34',1.2),
    wash('M 14 16 C 22 18 29 25 32 37 C 21 36 16 29 14 16 Z',.055),
    wash('M 50 16 C 42 18 35 25 32 37 C 43 36 48 29 50 16 Z',.09),
    line('M 25 35 C 17 29 15 23 14 16 C 20 18 25 21 28 25 M 39 35 C 47 29 49 23 50 16 C 44 18 39 21 36 25',1.25),
    wash('M 32 39 C 24 34 22 24 32 7 C 42 24 40 34 32 39 Z',.065),
    line('M 32 39 C 24 34 22 24 32 7 C 42 24 40 34 32 39 Z',1.25),
    line('M 31 15 C 28 25 28 30 31 35 M 34 18 C 36 25 36 30 34 34 M 18 22 C 20 27 22 30 25 32 M 46 22 C 44 27 42 30 39 32 M 14 32 C 17 35 21 37 24 37 M 50 32 C 47 35 43 37 40 37',.65,.53),
    line('M 32 41 C 30 46 30 48 31 51',1.0,.85),
    wash('M 11 53 C 17 45 39 45 52 51 L 34 52 L 46 57 C 33 61 18 60 11 53 Z',.07),
    line('M 11 53 C 17 45 39 45 52 51 L 34 52 L 46 57 C 33 61 18 60 11 53 Z',1.05),
    line('M 31 52 C 26 51 20 51 15 53 M 31 52 C 27 52 24 54 22 56 M 31 52 C 32 54 35 56 39 57 M 31 52 C 27 49 22 49 19 50',.6,.5),
    ...warm([line('M 28 39 C 30 41 34 41 36 39',.85,.85)]),
    ...cool([line('M 7 56 C 12 58 16 58 19 58 M 48 58 C 52 57 55 56 57 54',.65,.5)]),
  ],
  '小满': [
    ...warm(ear(31,10,-2,false)),
    ...blade(30,57,11,32,6),...blade(32,57,54,37,-4),
    line('M 30 46 L 30 58 M 35 47 L 32 58 M 13 58 C 23 56 41 58 50 57',.9,.55),
  ],
  '芒种': [
    ...warm(ear(28,15,8,true)),...blade(27,57,9,36,5),...blade(29,57,54,30,-3),
    line('M 28 50 L 23 59 M 34 49 L 28 59 M 45 43 C 47 40 50 39 53 39',1,.6),
  ],
  '夏至': [
    ...sun(32,20,10),
    wash('M 7 47 C 17 39 23 39 32 46 C 39 51 48 49 57 42 C 50 54 19 55 7 47 Z',.055),
    line('M 7 47 C 17 39 23 39 32 46 C 39 51 48 49 57 42',1.15),
    ...cool([line('M 10 53 C 22 47 27 53 37 54 C 44 55 51 52 56 50 M 20 58 C 29 56 38 59 45 57',.75,.7)]),
    line('M 16 44 C 21 43 24 44 27 46 M 41 49 C 46 48 49 46 51 45',.6,.4),
  ],
  '小暑': [
    wash('M 31 45 C 19 43 8 34 8 24 C 8 14 18 8 31 8 C 44 8 55 14 56 24 C 56 34 44 43 34 45 L 34 56 C 34 60 30 60 30 56 Z',.05),
    line('M 31 45 C 19 43 8 34 8 24 C 8 14 18 8 31 8 C 44 8 55 14 56 24 C 56 34 44 43 34 45 L 34 56 C 34 60 30 60 30 56 Z',1.25),
    ...warm([line('M 12 24 C 12 17 21 11 31 11 C 42 11 52 17 52 24',.75,.75),line('M 31 49 L 33 49 M 31 52 L 33 52',.85,.8)]),
    line('M 32 13 L 32 42 M 15 22 C 21 27 27 36 31 42 M 21 15 C 26 25 28 35 31 42 M 42 15 C 38 24 35 36 33 42 M 49 22 C 43 27 37 36 33 42 M 14 30 C 22 34 27 39 30 42 M 50 30 C 42 34 37 39 34 42',.7,.68),
    line('M 18 23 C 27 18 38 19 46 24 M 22 30 C 28 27 37 27 43 31 M 28 38 C 30 37 34 37 36 38',.6,.4),
  ],
  '大暑': [
    ...sun(45,15,7),
    // Curled lotus leaf; the ribs bend toward the rolled edge.
    wash('M 8 42 C 8 29 20 23 30 25 C 41 27 47 34 49 44 C 43 49 18 51 8 42 Z',.065),
    wash('M 8 42 C 17 46 39 48 49 44 C 47 50 21 54 8 42 Z',.13),
    line('M 8 42 C 8 29 20 23 30 25 C 41 27 47 34 49 44 C 40 49 18 49 8 42 Z',1.25),
    line('M 12 44 C 22 51 43 51 49 44 M 29 38 C 31 45 33 51 38 55 C 42 58 47 57 50 55',1.0,.85),
    line('M 29 38 C 24 38 18 40 12 41 M 29 38 C 25 35 19 31 16 30 M 29 38 C 27 34 25 29 26 27 M 29 38 C 32 35 35 32 37 31 M 29 38 C 35 37 41 39 46 42 M 29 38 C 27 42 24 44 21 46 M 29 38 C 33 42 38 45 43 46',.7,.62),
    line('M 9 20 C 6 16 12 13 10 10 M 18 18 C 15 14 21 10 19 7 M 8 56 C 16 54 22 57 27 56',.75,.43),
  ],
  '立秋': [
    line('M 12 54 C 18 48 22 41 29 33',1.6),
    ...warm(leaf(20,45,52,8,17,5)),
    line('M 7 24 C 10 19 17 16 24 17 M 9 29 C 13 25 16 24 20 24 M 38 51 C 46 52 53 48 57 43',.85,.45),
    ...warm(leaf(43,54,52,49,2.8,0)),
  ],
  '处暑': [
    wash('M 12 32 C 12 11 42 11 42 32 Z',.065),line('M 12 32 C 12 11 42 11 42 32 M 7 32 L 51 32',1.4),
    line('M 27 10 L 27 7 M 10 17 L 7 14 M 44 17 L 47 14 M 18 28 C 19 19 30 16 36 23',.9,.5),
    line('M 7 41 C 18 36 31 44 46 40 C 54 38 59 42 56 46 C 54 49 50 47 51 45 M 12 49 C 20 47 27 52 35 50',1.25,.85),
    ...warm(leaf(39,55,53,53,4,1)),
  ],
  '白露': [
    ...leaf(8,40,56,32,14,5),
    ...droplet(31,24.5,4.2),
    ...droplet(46,48,2.3),
    ...cool([line('M 9 47 C 17 52 29 52 36 50',.65,.38)]),
    ...ripple(28,57,16),
  ],
  '秋分': [
    ...sun(19,17,7,false),
    ...cool([wash('M 45 8 C 35 13 38 27 50 27 C 37 35 27 14 45 8 Z',.14),line('M 45 8 C 35 13 38 27 50 27 C 37 35 27 14 45 8 Z',1.1),line('M 37 14 C 34 19 38 26 42 27',.6,.4)]),
    line('M 8 33 L 56 33 M 31 29 L 31 37',.85,.5),
    line('M 14 57 C 25 50 40 50 52 41',1.5),
    ...leaf(24,52,19,40,4,1),...leaf(34,49,38,38,4,1),...leaf(39,47,52,49,4.5,1),
    dot(54,16,.55),
  ],
  '寒露': [
    line('M 13 57 C 27 44 34 27 37 10',1.6),
    ...leaf(22,47,9,30,6,2),...leaf(28,36,50,25,8,3),...leaf(34,23,27,9,4,1),
    ...droplet(45,44,3),...snow(52,11,4,false),
    line('M 9 59 C 20 56 32 58 39 56',.85,.4),
  ],
  '霜降': [
    wash(maple,.06),wash('M 20 48 C 26 38 33 27 38 8 C 38 14 41 20 42 25 C 46 25 50 23 53 22 C 52 27 49 31 48 34 C 50 35 54 36 56 36 C 52 40 47 42 44 45 C 44 47 45 50 44 51 C 40 51 34 48 31 48 C 28 49 24 49 20 48 Z',.07),
    line(maple,1.35),...warm([line('M 16 58 C 24 46 32 34 38 16',1.5)]),
    line('M 27 42 C 24 38 20 35 17 31 M 31 35 C 28 32 26 28 25 24 M 31 35 C 36 31 41 30 46 28 M 25 46 C 30 46 35 47 40 46 M 34 29 C 36 28 38 28 40 27 M 22 36 L 20 39 M 37 32 L 40 35 M 33 46 L 36 42',.85,.6),
    ...snow(12,12,4,false),...snow(53,54,3,false),
  ],
  '立冬': [
    line('M 29 53 C 31 38 30 22 33 8 M 31 27 C 25 24 20 21 18 16 L 17 9 M 24 21 C 19 22 15 21 12 21 M 31 38 C 37 33 44 30 47 24 L 48 16 M 42 29 C 45 31 49 32 53 31 M 32 18 C 36 17 39 13 41 11',1.65),
    line('M 29 52 C 28 44 28 38 28 33 M 19 16 C 16 15 13 12 11 11 M 39 32 C 40 29 40 27 39 25 M 30 42 L 32 40 M 31 22 L 32 20',.8,.6),
    wash('M 6 56 C 17 49 28 51 36 54 C 44 58 51 56 58 53 L 58 58 L 6 58 Z',.07),line('M 6 56 C 17 49 28 51 36 54 C 44 58 51 56 58 53',1.1,.8),
    ...snow(12,36,3,false),dot(52,9),dot(50,43),
  ],
  '小雪': [
    ...cloud(),
    ...snow(24,40,6.5,true),...snow(45,46,3.8,false),...snow(10,46,2.5,false),
    ...cool([dot(53,38,.5),dot(35,51,.55),
      wash('M 8 57 C 17 52 26 58 34 55 C 43 52 48 57 56 54 L 56 57 C 39 61 19 58 8 59 Z',.055),
      line('M 8 57 C 17 52 26 58 34 55 C 43 52 48 57 56 54',.8,.62)]),
  ],
  '大雪': [
    ...snow(32,26,18,true),...cool([line('M 28 23.7 L 32 21.4 L 36 23.7 L 36 28.3 L 32 30.6 L 28 28.3 Z',.75,.65)]),
    ...snow(9,14,3,false),...snow(55,42,3,false),dot(51,11),dot(13,41),
    wash('M 5 54 C 17 46 27 58 39 52 C 48 47 54 50 59 52 L 59 58 L 5 58 Z',.085),
    line('M 5 54 C 17 46 27 58 39 52 C 48 47 54 50 59 52 M 16 59 C 27 56 35 60 46 57',1.15,.8),
  ],
  '冬至': [
    ...sun(37,20,8,false),
    ...warm([line('M 37 9 L 37 6 M 25 13 L 23 11 M 49 13 L 51 11',.75,.55)]),
    ...cool([wash('M 24 30 C 28 35 34 40 40 46 L 32 45 L 26 39 Z',.14)]),
    ...cool([wash('M 49 39 L 57 48 L 47 46 Z',.095)]),
    line('M 7 47 C 13 41 18 35 24 30 C 30 36 35 41 40 46 C 43 44 46 41 49 39 C 52 42 55 46 58 48',1.2),
    line('M 19 36 L 23 38 L 26 36 M 26 39 L 29 42 M 46 43 L 49 45 L 51 44 M 7 53 C 18 49 32 56 43 52 C 49 50 54 51 58 52',.75,.65),
    ...cool([line('M 18 58 C 25 56 34 60 42 57',.65,.5)]),line('M 33 45 L 36 48',.6,.4),
  ],
  '小寒': [
    // Visible branch segments stop at the flowers instead of crossing their faces.
    line('M 8 56 C 16 49 20 45 23 40 M 34 28 C 37 24 38 23 40 21 M 22 43 C 18 38 17 34 16 29 M 36 29 C 41 31 45 30 48 28',1.4),
    line('M 10 55 C 16 50 19 46 20 43 M 18 37 L 20 38',.65,.45),
    ...blossom(28,33,9,-.12),...blossom(46,13.5,7.7,.34),
    ...leaf(16,30,11,21,3,0),...leaf(45,29,53,25,3.2,0),
    ...warm([wash(ellipse(36,23,1.5,2.2),.12),line('M 35 25 C 32 22 35 19 37 21 C 38 23 37 25 35 25 Z',.9,.85)]),
    line('M 8 59 C 19 56 29 58 38 56',.65,.38),...snow(13,11,2.8,false),
  ],
  '大寒': [
    ...snow(32,30,23,true),
    ...cool([line('M 25 26 L 32 22 L 39 26 L 39 34 L 32 38 L 25 34 Z',1.05)]),
    ...cool([wash('M 29 28.3 L 32 26.5 L 35 28.3 L 32 30 Z',.13),line('M 29 28.3 L 32 26.5 L 35 28.3 L 35 31.7 L 32 33.5 L 29 31.7 Z',.7,.7)]),
    ...Array.from({length:6},(_,i)=>{
      const a=i*Math.PI/3-Math.PI/2,x=32+Math.cos(a)*18,y=30+Math.sin(a)*18;
      return dot(x,y,.7);
    }),
    ...snow(9,9,2,false),...snow(55,52,2,false),dot(53,9,.6),dot(11,53,.6),
  ],
};

// Ice and snow use one coherent cool ink, including their facet nodes and snowbanks.
masters['大寒'] = cool(masters['大寒']);
masters['大雪'] = cool(masters['大雪']);

// Platform renderers share a 24-unit viewport; preserve independent 64-unit geometry.
export const largeArt = Object.fromEntries(Object.entries(masters).map(([term,shapes]) => [term, shapes.map(shape => ({
  ...shape,
  d: shape.d.replace(/-?\d*\.?\d+(?:e[+-]?\d+)?/gi, n => String(Number((Number(n)*24/64).toFixed(4)))),
  width: Number((shape.width*24/64).toFixed(4)),
}))]));
