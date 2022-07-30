(* Delphi Unit
   Long integer arithmetic
   =======================
   refer to: ct 4/89

   © Dr. J. Rathlev, D-24222 Schwentinental (info(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   Version 1.0 : Turbo Pascal, July 1989  (see unit XLongInt)
   Version 2.0 : Delphi 10, June 2018
   last modified: July 2022
  *)

unit XMathUtils;

interface

(* Notes on implicit and explicit:
   ===============================
   var
     xi : TXLongWord;
     n  : int64;
     x  : double;
   Implicit conversion:
     allowed: xi:=n; xi:=x;
   Explicit conversion:
     allowed:     n:=int64(xi); x:=double(xi);
     not allowed: n:=xi; x:=xi;
*)

type
  TXLongWord = record
    XLen : integer;
    XVal : array of cardinal;
  private
    procedure Assign (const Value : TXLongWord);
    procedure SetToZero;
    procedure ShiftLeft;
    procedure ShiftRight;
    procedure Normalize;
  public
    constructor Create (Value : uint64);
    class operator Implicit (Value : cardinal) : TXLongWord;
    class operator Implicit (Value : integer) : TXLongWord;
    class operator Implicit (Value : int64) : TXLongWord;
    class operator Implicit (Value : uint64) : TXLongWord;
    class operator Implicit (Value : double) : TXLongWord;
    class operator Explicit (Value : TXLongWord) : integer;
    class operator Explicit (Value : TXLongWord) : cardinal;
    class operator Explicit (Value : TXLongWord) : int64;
    class operator Explicit (Value : TXLongWord) : uint64;
    class operator Explicit (Value : TXLongWord) : double;
    class operator Inc (const Value : TXLongWord) : TXLongWord;
    class operator Dec (const Value : TXLongWord) : TXLongWord;
    class operator Equal (const ValL,ValR : TXLongWord) : boolean;
    class operator NotEqual (const ValL,ValR : TXLongWord) : boolean;
    class operator GreaterThan (const ValL,ValR : TXLongWord) : boolean;
    class operator GreaterThanOrEqual (const ValL,ValR : TXLongWord) : boolean;
    class operator LessThan (const ValL,ValR : TXLongWord) : boolean;
    class operator LessThanOrEqual (const ValL,ValR : TXLongWord) : boolean;
    class operator Add (const ValL,ValR : TXLongWord) : TXLongWord;
    class operator Subtract (const ValL,ValR : TXLongWord) : TXLongWord;
    class operator Multiply (const ValL,ValR : TXLongWord) : TXLongWord;
    class operator Divide (const ValL,ValR : TXLongWord) : TXLongWord;
    class operator IntDivide (const ValL,ValR : TXLongWord) : TXLongWord;
    class operator Modulus (const ValL,ValR : TXLongWord) : TXLongWord;
    class operator LeftShift (const Value : TXLongWord; Shift : cardinal) : TXLongWord;
    class operator RightShift (const Value : TXLongWord; Shift : cardinal) : TXLongWord;
    function IsZero : boolean;
    function IsEven : boolean;
    function IsOdd : boolean;
    function High : cardinal;
    function ToString (GroupSep : char = #0) : string;
    function ToHex : string;
    end;

function TryStrToXLong (const s : string; var Value : TXLongWord) : boolean;
function StrToXLong (const s : string) : TXLongWord;

function XDivMod (const ValM,ValD : TXLongWord; var ValR : TXLongWord) : TXLongWord;
function XMulDiv (const Value,Numerator,Denominator : TXLongWord) : TXLongWord;
function XPower (const x : TXLongWord; n : cardinal) : TXLongWord;
function XSqrt (Value :  TXLongWord) : TXLongWord;
function XFactorial (const Value : cardinal) : TXLongWord;
function XBinomial (n,k : cardinal) : TXLongWord;

// ----------------------------------------------------------------
implementation

uses System.SysUtils, System.SysConst, System.Character;

const
  XHBit       = $80000000;
  XMask       = $7FFFFFFF;
  MaxCardinal = $FFFFFFFF;
  MaxInt64    = $7FFFFFFFFFFFFFFF;
  MaxUInt64   = $FFFFFFFFFFFFFFFF;

procedure ZeroDivideError;
begin
  raise EZeroDivide.Create(SDivByZero);
  end;

procedure ConvertError (const s : string);
begin
  raise EConvertError.Create(Format(SInvalidInteger,[s]));
  end;

constructor TXLongWord.Create (Value : uint64);
begin
  self:=Value;
  end;

procedure TXLongWord.Assign (const Value : TXLongWord);
var
  i : integer;
begin
  XLen:=Value.XLen;
  SetLength(XVal,XLen);
  for i:=0 to XLen-1 do XVal[i]:=Value.XVal[i];
  end;

procedure TXLongWord.SetToZero;
begin
  XLen:=0; XVal:=nil;
  end;

procedure TXLongWord.ShiftLeft;
var
  i : integer;
  cy,sum : cardinal;
begin
  cy:=0;
  for i:=0 to XLen-1 do begin
    sum:=(XVal[i] shl 1)+cy;
    if (sum and XHBit)<>0 then begin
      cy:=1; sum:=sum and XMask;
      end
    else cy:=0;
    XVal[i]:=sum;
    end;
  if cy=1 then begin
    inc(XLen); SetLength(XVal,XLen); XVal[XLen-1]:=cy;
    end;
  end;

procedure TXLongWord.ShiftRight;
var
  i : integer;
  cy,sum : cardinal;
begin
  cy:=0;
  for i:=XLen-1 downto 0 do begin
    sum:=XVal[i]+cy;
    if (sum and 1)<>0 then cy:=XHBit
    else cy:=0;
    XVal[i]:=sum shr 1;
    end;
  if XVal[XLen-1]=0 then begin
    dec(XLen); SetLength(XVal,XLen);
    end;
  end;

procedure TXLongWord.Normalize;
begin
  while (XVal[XLen-1]=0) and (XLen>0) do dec(XLen);
  SetLength(XVal,XLen);
  end;

function TXLongWord.IsEven : boolean;
begin
  if XLen=0 then Result:=true
  else Result:=(XVal[0] and 1)=0;
  end;

function TXLongWord.IsOdd : boolean;
begin
  if XLen=0 then Result:=false
  else Result:=(XVal[0] and 1)=1;
  end;

// ----------------------------------------------------------------
class operator TXLongWord.Implicit(Value : cardinal) : TXLongWord;
begin
  Result:=uint64(Value);
  end;

class operator TXLongWord.Implicit(Value : integer) : TXLongWord;
begin
  if Value<=0 then Result.SetToZero
  else with Result do begin
    XLen:=1; SetLength(XVal,XLen); XVal[0]:=Value;
    end
  end;

class operator TXLongWord.Implicit(Value : uint64) : TXLongWord;
begin
  with Result do begin
    XLen:=3; SetLength(XVal,XLen);
    XVal[0]:=Value and XMask;
    Value:=Value shr 31;
    XVal[1]:=Value and XMask;
    Value:=Value shr 31;
    XVal[2]:=Value;
    Normalize;
    end;
  end;

class operator TXLongWord.Implicit(Value : int64) : TXLongWord;
begin
  if Value<=0 then Result.SetToZero
  else Result:=uint64(Value);
  end;

class operator TXLongWord.Implicit (Value : double) : TXLongWord;
var
  m : int64;
  n : integer;
begin
  if Value<0.5 then Result.SetToZero
  else begin
    Value:=Value+0.5; // round
    n:=Value.Exp-1075; m:=Value.Mantissa;
    Result:=m;
    if n<0 then Result:=Result shr (-n)
    else if n>0 then Result:=Result shl n;
    end;
  end;

class operator TXLongWord.Explicit (Value : TXLongWord) : cardinal;
var
  i : integer;
begin
  if Value>MaxCardinal then Result:=MaxCardinal
  else with Value do begin
    Result:=0;
    for i:=XLen-1 downto 0 do Result:=Result shl 31+XVal[i];
    end;
  end;

class operator TXLongWord.Explicit (Value : TXLongWord) : integer;
begin
  with Value do begin
    if XLen>1 then Result:=-1
    else if XLen=1 then Result:=XVal[0]
    else Result:=0;
    end;
  end;

class operator TXLongWord.Explicit (Value : TXLongWord) : uint64;
var
  i : integer;
begin
  if Value>MaxUInt64 then Result:=MaxUInt64
  else with Value do begin
    Result:=0;
    for i:=XLen-1 downto 0 do Result:=Result shl 31+XVal[i];
    end;
  end;

class operator TXLongWord.Explicit (Value : TXLongWord) : int64;
begin
  if Value>MaxInt64 then Result:=-1
  else Result:=uint64(Value);
  end;

class operator TXLongWord.Explicit (Value : TXLongWord) : double;
var
  m,n : integer;
begin
  Result:=0;
  with Value do if not IsZero then begin
    m:=XVal[XLen-1];
    n:=31*XLen-52;
    while m>0 do begin
      m:=m shl 1; dec(n);
      end;
    if n<0 then Value:=Value shl (-n)
    else if n>0 then begin
      Value:=Value shr (n-1);
      if Value.XVal[0] and 1 <>0 then inc(Value.XVal[0]);
      Value:=Value shr 1;
      end;
    Result.Exp:=n+1075;
    Result.Frac:=int64(Value) and $FFFFFFFFFFFFF;
    end;
  end;

class operator TXLongWord.Inc (const Value : TXLongWord) : TXLongWord;
begin
  Result:=Value+1;
  end;

class operator TXLongWord.Dec (const Value : TXLongWord) : TXLongWord;
begin
  Result:=Value-1;
  end;

class operator TXLongWord.Equal (const ValL,ValR : TXLongWord) : boolean;
var
  i : integer;
begin
  if ValL.XLen<ValR.XLen then Result:=false
  else if ValL.XLen>ValR.XLen then Result:=false
  else if ValL.XLen=0 then Result:=true
  else begin
    i:=ValL.XLen-1;
    while (i>0) and (ValL.XVal[i]=ValR.XVal[i]) do dec(i);
    Result:=i=0;
    end;
  end;

class operator TXLongWord.NotEqual (const ValL,ValR : TXLongWord) : boolean;
var
  i : integer;
begin
  if ValL.XLen<ValR.XLen then Result:=true
  else if ValL.XLen>ValR.XLen then Result:=true
  else if ValL.XLen=0 then Result:=false
  else begin
    i:=ValL.XLen-1;
    while (i>0) and (ValL.XVal[i]<>ValR.XVal[i]) do dec(i);
    Result:=i=0;
    end;
  end;

class operator TXLongWord.GreaterThan (const ValL,ValR : TXLongWord) : boolean;
var
  i : integer;
begin
  if ValL.XLen<ValR.XLen then Result:=false
  else if ValL.XLen>ValR.XLen then Result:=true
  else if ValL.XLen=0 then Result:=false
  else begin
    i:=ValL.XLen-1;
    while (i>0) and (ValL.XVal[i]=ValR.XVal[i]) do dec(i);
    Result:=ValL.XVal[i]>ValR.XVal[i];
    end;
  end;

class operator TXLongWord.GreaterThanOrEqual (const ValL,ValR : TXLongWord) : boolean;
var
  i : integer;
begin
  if ValL.XLen<ValR.XLen then Result:=false
  else if ValL.XLen>ValR.XLen then Result:=true
  else if ValL.XLen=0 then Result:=true
  else begin
    i:=ValL.XLen-1;
    while (i>0) and (ValL.XVal[i]=ValR.XVal[i]) do dec(i);
    Result:=ValL.XVal[i]>=ValR.XVal[i];
    end;
  end;

class operator TXLongWord.LessThan (const ValL,ValR : TXLongWord) : boolean;
var
  i : integer;
begin
  if ValL.XLen<ValR.XLen then Result:=true
  else if ValL.XLen>ValR.XLen then Result:=false
  else if ValL.XLen=0 then Result:=false
  else begin
    i:=ValL.XLen-1;
    while (i>0) and (ValL.XVal[i]=ValR.XVal[i]) do dec(i);
    Result:=ValL.XVal[i]<ValR.XVal[i];
    end;
  end;

class operator TXLongWord.LessThanOrEqual (const ValL,ValR : TXLongWord) : boolean;
var
  i : integer;
begin
  if ValL.XLen<ValR.XLen then Result:=true
  else if ValL.XLen>ValR.XLen then Result:=false
  else if ValL.XLen=0 then Result:=true
  else begin
    i:=ValL.XLen-1;
    while (i>0) and (ValL.XVal[i]=ValR.XVal[i]) do dec(i);
    Result:=ValL.XVal[i]<=ValR.XVal[i];
    end;
  end;

function TXLongWord.IsZero : Boolean;
begin
  Result:=XLen=0;
  end;

class operator TXLongWord.Add (const ValL,ValR : TXLongWord) : TXLongWord;
var
  i : integer;
  cy,sum : cardinal;
begin
  with Result do begin
    if ValL.XLen<ValR.XLen then XLen:=ValR.XLen else XLen:= ValL.XLen;
    SetLength(XVal,XLen);
    cy:=0;  // carry
    for i:=0 to XLen-1 do begin
      if i<ValL.XLen then sum:=ValL.XVal[i]+cy else sum:=cy;
      if i<ValR.XLen then sum:=sum+ValR.XVal[i];
      if (sum and XHBit)<>0 then begin
        cy:=1; sum:=sum and XMask;
        end
      else cy:=0;
      XVal[i]:=sum;
    end;
    if cy=1 then begin
      inc(XLen); SetLength(XVal,XLen); XVal[XLen-1]:=cy;
      end;
    end;
  end;

class operator TXLongWord.Subtract (const ValL,ValR : TXLongWord) : TXLongWord;
var
  i,sum : integer;
  cy    : cardinal;
begin
  with Result do begin
    if ValL<ValR then SetToZero
    else begin
      XLen:=ValL.XLen; SetLength(XVal,XLen);
      cy:=0;  // carry
      for i:=0 to XLen-1 do begin
        sum:=ValL.XVal[i]-cy;
        if i<ValR.XLen then sum:=sum-ValR.XVal[i];
        if sum<0 then begin
          cy:=1; sum:=sum and XMask;
          end
        else cy:=0;
        XVal[i]:=sum;
        end;
      Normalize;
      end;
    end;
  end;

class operator TXLongWord.Multiply (const ValL,ValR : TXLongWord) : TXLongWord;
var
  a,b : TXLongWord;
begin
  if ValL>ValR then begin
    a.Assign(ValL); b.Assign(ValR);
    end
  else begin
    b.Assign(ValL); a.Assign(ValR);
    end;
  Result:=0;
  while b.XLen>0 do begin
    if (b.XVal[0] and 1)=1 then Result:=Result+a;
    a.ShiftLeft; b.ShiftRight;
    end;
  a.SetToZero; b.SetToZero;
  end;

class operator TXLongWord.IntDivide (const ValL,ValR : TXLongWord) : TXLongWord;
var
  a,b : TXLongWord;
  i,n : integer;
begin
  if ValR.IsZero then ZeroDivideError;
  a.Assign(ValL); b.Assign(ValR);
  Result:=0; n:=0;
  while b<=a do begin
    b.ShiftLeft; inc(n);
    end;
  Result:=0;
  for i:=1 to n do begin
    Result.ShiftLeft; b.ShiftRight;
    if b<=a then begin
      a:=a-b; inc(Result);
      end;
    end;
  a.SetToZero; b.SetToZero;
  end;

class operator TXLongWord.Divide (const ValL,ValR : TXLongWord) : TXLongWord;
begin
  Result:=ValL div ValR;
  end;

class operator TXLongWord.Modulus (const ValL,ValR : TXLongWord) : TXLongWord;
var
  b : TXLongWord;
  i,n : integer;
begin
  if ValR.IsZero then ZeroDivideError;
  Result.Assign(ValL); b.Assign(ValR);
  n:=0;
  while b<=Result do begin
    b.ShiftLeft; inc(n);
    end;
  for i:=1 to n do begin
    b.ShiftRight;
    if b<=Result then Result:=Result-b;
    end;
  b.SetToZero;
  end;

class operator TXLongWord.LeftShift (const Value : TXLongWord; Shift : cardinal) : TXLongWord;
var
  i : integer;
begin
  Result.Assign(Value);
  for i:=1 to Shift do Result.ShiftLeft;
  end;

class operator TXLongWord.RightShift (const Value : TXLongWord; Shift : cardinal) : TXLongWord;
var
  i : integer;
begin
  Result.Assign(Value);
  for i:=1 to Shift do Result.ShiftRight;
  end;

// return highest word
function TXLongWord.High : cardinal;
begin
  if XLen=0 then Result:=0
  else Result:=XVal[XLen-1];
  end;

// ----------------------------------------------------------------
function TXLongWord.ToString (GroupSep : char) : string;
var
  a,b,c : TXLongWord;
  n     : integer;
begin
  if XLen=0 then Result:='0'
  else begin
    a.Assign(self); b:=10;
    Result:=''; n:=0;
    repeat
      a:=XDivMod(a,b,c);
      Result:=chr(byte(c)+48)+Result;
      if (GroupSep<>#0) and (n mod 3=2) then Result:=GroupSep+Result;
      inc(n);
      until a.XLen=0;
    a.SetToZero; b.SetToZero; c.SetToZero;
    end;
  end;

function TXLongWord.ToHex : string;
var
  a,b,c : TXLongWord;
begin
  if XLen=0 then Result:='0'
  else begin
    a.Assign(self); b:=16;
    Result:='';
    repeat
      a:=XDivMod(a,b,c);
      if c<10 then Result:=chr(byte(c)+48)+Result
      else Result:=chr(byte(c)+55)+Result;
      until a.XLen=0;
    a.SetToZero; b.SetToZero; c.SetToZero;
    end;
  end;

// ----------------------------------------------------------------
function TryStrToXLong (const s : string; var Value : TXLongWord) : boolean;
var
  i,n : integer;
begin
  n:=length(s); Value:=0;
  Result:=n>0;
  if Result then for i:=1 to n do begin
    Result:=IsNumber(s[i]);
    if Result then Value:=10*Value+StrToInt(s[i])
    else Break;
    end;
  end;

function StrToXLong (const s : string) : TXLongWord;
begin
  if not TryStrToXLong(s,Result) then ConvertError(s);
  end;

// ----------------------------------------------------------------
// Division with remainder
function XDivMod (const ValM,ValD : TXLongWord; var ValR : TXLongWord) : TXLongWord;
var
  a,b : TXLongWord;
  i,n : integer;
begin
  if ValD.IsZero then ZeroDivideError;
  a.Assign(ValM); b.Assign(ValD);
  Result:=0; n:=0;
  while b<=a do begin
    b.ShiftLeft; inc(n);
    end;
  Result:=0;
  for i:=1 to n do begin
    Result.ShiftLeft; b.ShiftRight;
    if b<=a then begin
      a:=a-b; inc(Result);
      end;
    end;
  ValR.Assign(a); a.SetToZero; b.SetToZero;
  end;

// similar to Winapi.Windows.MulDiv
function XMulDiv (const Value,Numerator,Denominator : TXLongWord) : TXLongWord;
begin
  Result:=Value*Numerator div Denominator;
  end;

// ----------------------------------------------------------------
// sample value:
// 85! = 2817104114 3805502769 4947944226 0611594800 5663433057 4206405101 9127525600 2615979593 3451040286 4523409240 1827512320 0000000000 000000000
function XFactorial (const Value : cardinal) : TXLongWord;
begin
  if Value<1 then Result:=1
  else Result:=Value*XFactorial(Value-1);
  end;

// sample value
// (567|123) = 247726570 0593035316 1228465215 5160703700 4581235132 0074048742 1912694467 0389413106 0045931597 6888117015 6172405583 8575252758 008856000
function XBinomial (n,k : cardinal) : TXLongWord;
var
  i : cardinal;
begin
  if 2*k>n then k:=n-k;
  if k=0 then Result:=1
  else begin
    Result:=n;
    for i:=2 to k do Result:=Result*(n+1-i) div i;
    end;
  end;

// ----------------------------------------------------------------
// computes x^n
function XPower (const x : TXLongWord; n : cardinal) : TXLongWord;
var
  a   : TXLongWord;
begin
  a.Assign(x); Result:=1;
  while n>0 do begin
    if n and 1 = 1 then Result:=a*Result;
    n:=n shr 1;
    if n>0 then a:=a*a;
    end;
  a.SetToZero;
  end;

// Long Integer square root
// refer to: http://www.azillionmonkeys.com/qed/ulerysqroot.pdf
function XSqrt (Value : TXLongWord) : TXLongWord;
var
  j,n : integer;
  tmp,sum : TXLongWord;
const
  XSqCarry = $60000000;
  XSqMask  = $1FFFFFFF;

  // Shift Value 2 bits left, add carry to tmp
  procedure ShiftLeft2 (var Value,Temp : TXLongWord);
  var
    n : cardinal;
  begin
    n:=(Value.High and XSqCarry) shr 29;
    with Temp do begin
      if XLen=0 then begin
        XLen:=1; SetLength(XVal,XLen); XVal[0]:=n;
        end
      else begin
        ShiftLeft; ShiftLeft;
        XVal[0]:=XVal[0]+n;
        end;
      end;
    with Value do XVal[XLen-1]:=XVal[XLen-1] and XSqMask;
    Value:=Value shl 2;
    end;

begin
  Result:=0;
  if not Value.IsZero then begin
    with Value do begin
      Normalize;
      if XLen and 1 <>0 then begin       // needs even number of bytes
        inc(XLen); SetLength(XVal,XLen); XVal[XLen-1]:=0;
        end;
      n:=31*XLen div 2;
      end;
    tmp:=0;
    for j:=1 to n do begin
      ShiftLeft2(Value,tmp);
      Result:=Result shl 1;
      sum:=Result shl 1 +1;
      if sum<=tmp then begin
        tmp:=tmp-sum;
        Result:=Result+1;
        end;
      end;
    if 2*tmp>=sum then Result:=Result+1;  // round
    tmp.SetToZero; sum.SetToZero;
    end;
  end;

end.
