(* Delphi Program
   Test for Long integer arithmetic
   ================================

   © Dr. J. Rathlev, D-24222 Schwentinental (info(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   June 2018

  *)

program TestXLong;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Winapi.Windows, XMathUtils;

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
  xi,yi,si,qi,ri : TXLongWord;
  n,k : cardinal;
  kk : int64;
  x,y : double;
  s   : string;
begin
  write('Enter number: '); readln(s);
  xi:=StrToXLong(s);
  writeln('XLong :  ',xi.ToString);
  writeln;

  xi:=1234567890;
  yi:=0987654321;
  x:=9.223372333333337e125;
  writeln(Format('Double:   %s',[x.ToString]));
  qi:=x;
  writeln('XLong :  ',qi.ToString);
  writeln('         ',qi.ToHex);
  y:=double(qi/3);
  writeln(Format('Double:   %s',[y.ToString]));

  kk:=int64(xi*yi);
  qi:=kk;
  writeln('Int64 :  ',kk);
  writeln('XLong :  ',qi.ToString);
  writeln('         ',qi.ToHex);
  qi:=qi shl 32;
  writeln('XLong :  ',qi.ToString);
  writeln('         ',qi.ToHex);
  si:=xi*yi+123;
  writeln('XLong :  ',si.ToString);
  si:=XDivMod(si,yi,ri);
  writeln('         ',si.ToString);
  writeln('         ',ri.ToString);
  writeln;

  k:=4;
  yi:=XPower(xi,k);
  writeln(Format('Power: %s^%u = %s',[xi.ToString,k,yi.ToString]));

  si:=XSqrt(yi);
  writeln(Format('Sqrt(%s) = %s',[yi.ToString,si.ToString]));
  yi:=XSqrt(si);
  writeln(Format('Sqrt(%s) = %s',[si.ToString,yi.ToString]));
  writeln;

  k:=85;
  si:=XFactorial(k);
  writeln(Format('Fak(%u)= %s',[k,si.ToString(' ')]));

  n:=567; k:=123;
  writeln(Format('Binomial: (%u|%u) = %s',[n,k,XBinomial(n,k).ToString(' ')]));

  WaitForAnyKey;
  end.

