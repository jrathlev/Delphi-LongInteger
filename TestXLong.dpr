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
  System.SysUtils,
  XMathUtils in 'XMathUtils.pas';

var
  xi,yi,si,qi,ri : TXLongWord;
  k : int64;
  x,y : double;
begin
  xi:=1234567890;
  yi:=0987654321;
  x:=9.223372333333337e125;
  writeln(Format('Double:   %s',[x.ToString]));
  qi:=x;
  writeln('XLong :  ',qi.ToString);
  writeln('         ',qi.ToHex);
  y:=double(qi/3);
  writeln(Format('Double:   %s',[y.ToString]));

  k:=int64(xi*yi);
  qi:=k;
  writeln('Int64 :  ',k);
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
  si:=XFactorial(100);
  writeln('Fak(90)= ',si.ToString(' '));
  readln;
  end.

