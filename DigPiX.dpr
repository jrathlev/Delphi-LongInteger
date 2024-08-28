(* Pascal-Umsetzung des Programms "piqp" von P. Borwein
   (siehe (www.cecm.sfu.ca/personal/pborwein)
   J. Rathlev, Feb 2003 *)

(* This program employs the recently discovered digit extraction scheme
   to produce hex digits of pi.  This code is valid up to ic = 2^24 on
   systems with IEEE arithmetic.
   *)

program DigPiX;
{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Winapi.Windows, System.Math, XMathUtils;

const
  nhx = 12;
  ntp = 25;
  OutName = 'pi.out';

{ --------------------------------------------------------------- }
// read key from keyboard
function ReadKey : Word;
var
  nRead : Cardinal;
  Hdl   : THandle;
  Rec   : TInputRecord;
begin
  FlushConsoleInputBuffer(STD_INPUT_HANDLE);
  Hdl := GetStdHandle(STD_INPUT_HANDLE);
  repeat
    ReadConsoleInput(Hdl,Rec,1,nRead);
    until (Rec.EventType=KEY_EVENT) and (nRead=1) and (Rec.Event.KeyEvent.bKeyDown);
  Result := Rec.Event.KeyEvent.wVirtualKeyCode;
  end;

procedure WaitForAnyKey;
begin
  write('Strike any key to continue ...'); readkey; writeln;
  end;

{ --------------------------------------------------------------- }
var
  pid,C16P8 : extended;
  tp  : array [1..ntp] of extended;
  i,j,k,n,ic,nd : longint;
  xi,xp,xf  : TXLongWord;
  fo        : TextFile;
  stat      : array[0..9] of integer;

(* -----------------------------------------------------------------
(* This returns the first nx hex digits of the fraction of x. *)
function HexStr (const x : extended; nx : longint) : string;
const
  hx : string ='0123456789ABCDEF';
var
  y : extended;
  s : string;
  i : longint;
begin
  y:=abs(x); s:='';
  for i:=1 to nx do begin
    y:=16*frac(y);
    s:=s+hx[trunc(y)+1];
    end;
  HexStr:=s;
  end;

(* ---------------------------------------------------- *)
(* expm = 16^p mod ak.  This routine uses the left-to-right binary
   exponentiation scheme.  It is valid for  ak <= 2^24. *)
function expm (p, ak : longint) : extended;
var
  p1,pt,r : extended;
  i       : longint;
begin
  if ak=1 then expm:=0
  else begin
(* Find the greatest power of two less than or equal to p. *)
    for i:=1 to ntp do begin
      if tp[i]>p then break;
      end;
    pt:=tp[i-1];
    p1:=p; r:=1;

(*   Perform binary exponentiation algorithm modulo ak. *)
    while pt>=1 do begin
      if p1>=pt then begin
        r:=FMod(16*r,ak);
        p1:=p1-pt;
        end;
      pt:=0.5*pt;
      if pt>=1 then r:=FMod(r*r,ak);
      end;
    expm:=FMod(r,ak);
    end;
  end;

(* ---------------------------------------------------- *)
(* This routine evaluates the series  sum_k 16^(ic-k)/(8*k+m)
   using the modular exponentiation technique. *)
function series (m,ic : longint) : extended;
const
  eps = 1E-17;
var
  s,t : extended;
  j,k : longint;
begin
  s:=0;
(*  Sum the series up to ic. *)
  for k:=0 to ic-1 do begin
    j:=8*k+m;
    t:=expm (ic-k,j);
    s:=s+t/j;
    end;

(* Compute a few terms where k >= ic. *)
  for k:=ic to ic+100 do begin
    j:=8*k+m;
    t:=Power(16,ic-k)/j;
    if t<eps then break;
    s:=frac(s+t);
    end;
  series:=s;
  end;

(* ---------------------------------------------------- *)
begin
(* first fill the power of two table tp. *)
  tp[1]:=1;
  for i:=2 to ntp do tp[i]:=2*tp[i-1];
  C16P8:=Power(16,8);
  write ('Anzahl der Stellen: '); readln (nd);
//  n:=999;
//  nd:=round(9.63*(n+1));
  n:=round(nd/9.63)-1;
  xi:=16; xf:=XPower(xi,8); xp:=0;
  writeln ('Berechnung von Pi nach P. Borwein');
  writeln ('Ausgabe mit ',nd,' Stellen hinter dem Komma');
  for k:=0 to n do begin
    ic:=k*8;
(*   ic is the hex digit position -- output begins at position ic + 1 *)
    pid:=4*series (1,ic);
    pid:=pid-2*series (4,ic);
    pid:=pid-series (5,ic);
    pid:=pid-series (6,ic);
    pid:=frac(pid)+1;
    xi:=trunc(pid*C16P8);
    xp:=xp*xf+xi
    end;
  n:=32*(n+1); j:=n mod 31;
  k:=n div 31;
(* normalize *)
  if j>0 then begin
    xp:=xp shl (31-j);
    inc(k);
    end;
  for i:=0 to 9 do stat[i]:=0;
  AssignFile(fo,outname); rewrite(fo);
  write ('      3,');
  write (fo,'3.');
  for i:=1 to nd do begin
    xp:=10*xp;
    if xp.XLen=k then ic:=0 else ic:=xp.XVal[k];
    xp.XLen:=k;
    inc(stat[ic]);
    write (fo,chr(ic+48));
    write (chr(ic+48));
    if (i mod 50 =0) and (i<nd) then begin
      writeln;
      write (i+1:4,':   ');
      end
    else if i mod 10=0 then write(' ');
    end;
  CloseFile(fo);
  writeln;
//  writeln ('Statistik:');
//  for i:=0 to 9 do write (i:6);
//  writeln;
//  for i:=0 to 9 do write (stat[i]:6);
  WaitForAnyKey;
end.
