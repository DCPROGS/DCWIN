UNIT USE1432;

(* This is a version of USE1401.PAS that has been converted for use
   with Borland Delphi 2. It requires the 32-bit build of the Use1401
   library; Use1432.DLL. You should be able to use it by just including
   the Use1432 unit in you program.

   The conversion work was done by Stuart Baker, of the Institute of
   Neurology, London, to whom many thanks. The changes made were :

        replaced USE1401 with USE1432

        added stdcall as the calling type to the DLL function definitions

        defined type integer=smallint at the start to overcome the new
        default size of integer.

  As CED does not currently support Delphi 2, we have not tested this
  software and cannot guarantee it's correct operation, but we will be
  happy to try to help users sort out any problems that may be found.

*)

(****************************************************************************)
(*                                                                          *)
(* (C) Copyright Cambridge Electronic Design Ltd, 1992,1993                 *)
(*                                                                          *)
(* Title:      USE1401.PAS                                                  *)
(*                                                                          *)
(* Version:    1.0                                                          *)
(*                                                                          *)
(* Date:       16/10/93                                                     *)
(*                                                                          *)
(* Author:     Paul Cox                                                     *)
(* Translator: Julia Newsam                                                 *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)
(*                                                                          *)
(* Change log:                                                              *)
(*                                                                          *)
(*    DATE     REV                 DESCRIPTION                              *)
(* ----------- --- ---------------------------------------------------------*)
(*  21/Jul/92  PNC  First version intended to support Mac and DOS/Windows   *)
(*                  calls with same interface.                              *)
(*   8/Feb/93  TDB  Fixed up GetTransfer - MSDOS version needs separate     *)
(*                  structure to hold setup results from VXD.               *)
(*  24/Feb/93  TDB  USE1401.H protected against multiple includes           *)
(*  14/May/93  TDB  Multiple 1401 support added, extra handle parameter     *)
(*                  added to almost every function. Required driver level   *)
(*                  increased by 1 for both platforms.                      *)
(*  24/May/93  JCN  This version produced for TURBO Windows.                *)
(*  26/Oct/93  TDB  Changed SetTransfer to SetTransArea to match DLL.       *)
(*  20/Mar/96       Converted for Delphi 2 by Stuart Baker.                 *)
(*                                                                          *)
(****************************************************************************)
(*                                                                          *)
(* Return codes from functions                                              *)
(*                                                                          *)
(****************************************************************************)
INTERFACE
CONST U14ERR_NOERROR       =0;           (* no problems                    *)

CONST U14ERR_OFF           =-500;        (* 1401 there but switched off    *)
CONST U14ERR_NC            =-501;        (* 1401 not connected             *)
CONST U14ERR_ILL           =-502;        (* if present it is ill           *)
CONST U14ERR_NOIF          =-503;        (* I/F card missing               *)
CONST U14ERR_TIME          =-504;        (* 1401 failed to come ready      *)
CONST U14ERR_BADSW         =-505;        (* I/F card bad switches          *)
CONST U14ERR_PTIME         =-506;        (* 1401+ failed to come ready     *)
CONST U14ERR_NOINT         =-507;        (* couldn't grab the int vector   *)
CONST U14ERR_INUSE         =-508;        (* 1401 is already in use         *)
CONST U14ERR_NODMA         =-509;        (* couldn't get DMA channel       *)
CONST U14ERR_BADHAND       =-510;        (* handle provided was bad        *)
CONST U14ERR_BAD1401NUM    =-511;        (* 1401 number provided was bad   *)

CONST U14ERR_NO_SUCH_FN    =-520;        (* no such function               *)
CONST U14ERR_NO_SUCH_SUBFN =-521;        (* no such sub function           *)
CONST U14ERR_ERR_NOOUT     =-522;        (* no room in output buffer       *)
CONST U14ERR_ERR_NOIN      =-523;        (* no input in buffer             *)
CONST U14ERR_ERR_STRLEN    =-524;        (* string longer than buffer      *)
CONST U14ERR_LOCKFAIL      =-525;        (* failed to lock memory          *)
CONST U14ERR_UNLOCKFAIL    =-526;        (* failed to unlock memory        *)
CONST U14ERR_ALREADYSET    =-527;        (* area already set up            *)
CONST U14ERR_NOTSET        =-528;        (* area not set up                *)
CONST U14ERR_BADAREA       =-529;        (* illegal area number            *)

CONST U14ERR_NOFILE        =-540;        (* command file not found         *)
CONST U14ERR_READERR       =-541;        (* error reading command file     *)
CONST U14ERR_UNKNOWN       =-542;        (* unknown command                *)
CONST U14ERR_HOSTSPACE     =-543;        (* not enough host space to load  *)
CONST U14ERR_LOCKERR       =-544;        (* could not lock resource/command*)
CONST U14ERR_CLOADERR      =-545;        (* CLOAD command failed           *)

CONST U14ERR_TOXXXERR      =-560;        (* tohost/1401 failed             *)

CONST U14ERR_NO386ENH      =-580;        (* not 386 enhanced mode          *)
CONST U14ERR_NO1401DRIV    =-581;        (* no device driver               *)
CONST U14ERR_DRIVTOOOLD    =-582;        (* device driver too old          *)

CONST U14ERR_TIMEOUT       =-590;        (* timeout occurred               *)

CONST U14ERR_BUFF_SMALL    =-600;        (* buffer for getstring too small *)
CONST U14ERR_CBALREADY     =-601;        (* there is already a callback    *)
CONST U14ERR_BADDEREG      =-602;        (* bad parameter to deregcallback *)

CONST U14ERR_DRIVCOMMS     =-610;        (* failed talking to driver       *)
CONST U14ERR_OUTOFMEMORY   =-611;        (* neede memory and couldnt get it*)

CONST U14TYPE1401          = 0;          (* standard 1401                  *)
CONST U14TYPEPLUS          = 1;          (* 1401 plus                      *)
CONST U14TYPEU1401         = 2;          (* u1401                          *)
CONST U14TYPEUNKNOWN       =-1;          (* dont know                      *)

(****************************************************************************)
(*                                                                          *)
(* TYPE definitions                                                         *)
(*                                                                          *)
(****************************************************************************)

TYPE DWORD=LONGINT;

     INTEGER=SMALLINT;

     Tnums=ARRAY[0..50] OF LONGINT;                   {50 is arbitrary number}

     TpNums=^Tnums;   {address of array of longs, arg for LongsFrom functions}

TYPE T1401Registers=RECORD        { used for get/set standard 1401 registers }
                    sPC:INTEGER;
                    A:BYTE;
                    X:BYTE;
                    Y:BYTE;
                    stat:BYTE;
                    rubbish:BYTE;  (* unused *)
                    END;

TYPE TCSBlock=RECORD (*to communicate with 1401 driver status & control funcs *)
                CASE INTEGER OF
                0:(ints:ARRAY[0..10] OF INTEGER);
                1:(longs:ARRAY[0..4] OF LONGINT);
                2:(registers:T1401Registers);
                END;

FUNCTION U14LastErrCode(hand:INTEGER):INTEGER; stdcall;

FUNCTION U14Open1401(n1401:integer):integer; stdcall;
FUNCTION U14Close1401(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14Reset1401(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14TypeOf1401(hand:INTEGER):INTEGER; stdcall;

FUNCTION U14Stat1401(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14CharCount(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14LineCount(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14SendString(hand:INTEGER;PCharing:PChar):INTEGER; stdcall;
FUNCTION U14GetString(hand:INTEGER;lpBuffer:PChar;wMaxLen:WORD):INTEGER; stdcall;
FUNCTION U14SendChar(hand:INTEGER;cChar:CHAR):INTEGER; stdcall;
FUNCTION U14GetChar(hand:INTEGER;VAR cChar:CHAR):INTEGER; stdcall;

FUNCTION U14LdCmd(hand:INTEGER;command:PChar):INTEGER; stdcall;
FUNCTION U14Ld(hand:INTEGER;vl:PChar;str:PChar):DWORD; stdcall;

FUNCTION U14SetTransArea(hand:INTEGER; wArea:WORD; lpvBuff:POINTER;
                         dwLength:DWORD; eSize:INTEGER):INTEGER; stdcall;
FUNCTION U14UnSetTransfer(hand:INTEGER;wAreaNum:WORD):INTEGER; stdcall;

FUNCTION U14ToHost(hand:INTEGER;lpAddrHost:PChar;dwSize:DWORD;
                         lAddr1401:LONGINT; eSz:INTEGER):INTEGER; stdcall;
FUNCTION U14To1401(hand:INTEGER;lpAddrHost:PChar;dwSize:DWORD;
                         lAddr1401:LONGINT; eSz:INTEGER):INTEGER; stdcall;
FUNCTION U14StrToLongs(lpszBuff:PChar;palNums:TpNums;sMaxLongs:INTEGER):INTEGER; stdcall;
FUNCTION U14LongsFrom1401(hand:INTEGER;palBuff:TpNums;sMaxLongs:INTEGER):INTEGER; stdcall;

PROCEDURE U14SetTimeout(hand:INTEGER;lTimeout:LONGINT); stdcall;
FUNCTION  U14GetTimeout(hand:INTEGER):LONGINT; stdcall;
FUNCTION  U14OutBufSpace(hand:INTEGER):INTEGER; stdcall;
FUNCTION  U14BaseAddr1401(hand:INTEGER):LONGINT; stdcall;
FUNCTION  U14DriverVersion:LONGINT; stdcall;
FUNCTION  U14GetUserMemorySize(hand:INTEGER;VAR memorySize:LONGINT):INTEGER; stdcall;
FUNCTION  U14KillIO1401(hand:INTEGER):INTEGER; stdcall;

FUNCTION U14ZeroBlockCount(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14ByteCount(hand:INTEGER;VAR howMany:LONGINT):INTEGER; stdcall;
FUNCTION U14BlkTransState(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14StopCircular(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14StateOf1401(hand:INTEGER):INTEGER; stdcall;

FUNCTION U14Grab1401(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14Free1401(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14Step1401(hand:INTEGER):INTEGER; stdcall;
FUNCTION U14StepTill1401(hand:INTEGER;steps:LONGINT;targetAddress:LONGINT):INTEGER; stdcall;
FUNCTION U14Registers1401(hand:INTEGER;VAR csBlock:TCSBlock):INTEGER; stdcall;
FUNCTION U14Set1401Registers(hand:INTEGER;CONST csBlock:TCSBlock):INTEGER; stdcall;
FUNCTION U14SetOrin(hand:INTEGER;sOrIn:INTEGER):INTEGER; stdcall;

(****************************************************************************)
(*                                                                          *)
(* Windows/Dos Specifics                                                    *)
(*                                                                          *)
(****************************************************************************)

CONST  MINDRIVERMAJREV  =1;      (* minimum driver revision level we need   *)

CONST  CED_1401_Device_ID=  $2952;              (* VxD ID for CED_1401.386  *)

(* defines for type of function to ask driver to perform                    *)

CONST  U14_OPEN1401        =0;
CONST  U14_CLOSE1401       =1;
CONST  U14_SENDSTRING      =2;
CONST  U14_RESET1401       =3;
CONST  U14_GETCHAR         =4;
CONST  U14_SENDCHAR        =5;
CONST  U14_STAT1401        =6;
CONST  U14_LINECOUNT       =7;
CONST  U14_GETSTRING       =8;
CONST  U14_REGCALLBACK     =9;
CONST  U14_GETMONITORBUF   =10;
CONST  U14_SETTRANSFER     =11;
CONST  U14_UNSETTRANSFER   =12;
CONST  U14_GETCIRCSELECTOR =13;
CONST  U14_GETOUTBUFSPACE  =14;
CONST  U14_GETBASEADDRESS  =15;
CONST  U14_GETDRIVERREVISION=16;
CONST  U14_GETTRANSFER      =17;
CONST  U14_KILLIO1401       =18;
CONST  U14_BLKTRANSSTATE    =19;
CONST  U14_BYTECOUNT        =20;
CONST  U14_ZEROBLOCKCOUNT   =21;
CONST  U14_STOPCIRCULAR     =22;
CONST  U14_STATEOF1401      =23;

(* not yet implemented from here *)

CONST  U14_TYPEOF1401       =24;
CONST  U14_REGISTERS1401    =25;
CONST  U14_GRAB1401         =26;
CONST  U14_FREE1401         =27;
CONST  U14_STEP1401         =28;
CONST  U14_SET1401REGISTERS =29;
CONST  U14_STEPTILL1401     =30;
CONST  U14_SETORIN          =31;

(* end of unimplemented *)

CONST  U14_NOSUBFN       =0;

CONST  WM_CEDCALLBACK_STR='CEDCALLBACK';

CONST  GET_TX_MAXENTRIES =65;          (* Array size for GetTransfer struct *)

TYPE TXEntry=RECORD                     (* used for U14_GetTransfer results *)
                                          (* Info on a single mapped block *)
             physical:LONGINT;
             size:LONGINT;
             END;

TYPE TGet_TX_Block=RECORD               (* used for U14_GetTransfer results *)
                                                (* matches structure in VXD *)
                   size:LONGINT;
                   linear:LONGINT;
                   seg:INTEGER;
                   reserved:INTEGER;
                   avail:INTEGER;
                   used:INTEGER;
                   entries:ARRAY [0..GET_TX_MAXENTRIES-1] OF TXEntry;
                                               (*Array of mapped block info *)
                   END;

TYPE TGet_TX_BlockPnt=^TGet_TX_Block;
TYPE TU14Param=POINTER;
     TPWORD=^WORD;
     HWND=WORD;          {redefine the type for a window handle}
FUNCTION U14CallDriver(hand:INTEGER;bMainFn:BYTE;bSubFn:BYTE;
                                                  lpParams:TU14Param):INTEGER; stdcall;
FUNCTION U14Status1401(hand:INTEGER;bMainFn:BYTE;lpParams:TU14Param):INTEGER; stdcall;
FUNCTION U14Control1401(hand:INTEGER;bMainFn:BYTE;lpParams:TU14Param):INTEGER; stdcall;

FUNCTION U14RegCallBackWnd(n1401:INTEGER;hWnd:HWND;lpwMessCode:TPWORD):INTEGER; stdcall;
FUNCTION U14DeRegCallBackWnd(hWnd:HWND):INTEGER; stdcall;
FUNCTION U14GetMonBuff(lpBuffer:PChar;wMaxLen:WORD):INTEGER; stdcall;
FUNCTION U14GetCircSelector:INTEGER; stdcall;

FUNCTION U14GetTransfer(hand:INTEGER;VAR transBlock:TGet_TX_Block):INTEGER; stdcall;

Implementation
(* Almost all defined as external, as they are in USE1432.DLL*)
FUNCTION U14LastErrCode(hand:INTEGER):INTEGER;             stdcall; EXTERNAL  'USE1432';

FUNCTION U14Open1401(n1401:integer):integer;               stdcall; EXTERNAL  'USE1432';
FUNCTION U14Close1401(hand:INTEGER):INTEGER;               stdcall; EXTERNAL  'USE1432';
FUNCTION U14Reset1401(hand:INTEGER):INTEGER;               stdcall; EXTERNAL  'USE1432';
FUNCTION U14TypeOf1401(hand:INTEGER):INTEGER;              stdcall; EXTERNAL  'USE1432';

FUNCTION U14Stat1401(hand:INTEGER):INTEGER;                stdcall; EXTERNAL  'USE1432';
FUNCTION U14CharCount(hand:INTEGER):INTEGER;               stdcall; EXTERNAL  'USE1432';
FUNCTION U14LineCount(hand:INTEGER):INTEGER;               stdcall; EXTERNAL  'USE1432';
FUNCTION U14SendString(hand:INTEGER;PCharing:PChar):INTEGER;
                                                           stdcall; EXTERNAL  'USE1432';
FUNCTION U14GetString(hand:INTEGER;lpBuffer:PChar;wMaxLen:WORD):INTEGER;
                                                           stdcall; EXTERNAL  'USE1432';
FUNCTION U14SendChar(hand:INTEGER;cChar:CHAR):INTEGER;     stdcall; EXTERNAL  'USE1432';
FUNCTION U14GetChar(hand:INTEGER;VAR cChar:CHAR):INTEGER;
                                                           stdcall; EXTERNAL  'USE1432';

FUNCTION U14LdCmd(hand:INTEGER;command:PChar):INTEGER;     stdcall; EXTERNAL  'USE1432';
FUNCTION U14Ld(hand:INTEGER;vl:PChar;str:PChar):DWORD;     stdcall; EXTERNAL  'USE1432';

FUNCTION U14SetTransArea(hand:INTEGER; wArea:WORD; lpvBuff:POINTER;
                  dwLength:DWORD; eSize:INTEGER):INTEGER;  stdcall; EXTERNAL  'USE1432';
FUNCTION U14UnSetTransfer(hand:INTEGER;wAreaNum:WORD):INTEGER;
                                                           stdcall; EXTERNAL  'USE1432';

FUNCTION U14ToHost(hand:INTEGER;lpAddrHost:PChar;dwSize:DWORD;
                    lAddr1401:LONGINT;eSz:INTEGER):INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION U14To1401(hand:INTEGER;lpAddrHost:PChar;dwSize:DWORD;
                    lAddr1401:LONGINT;eSz:INTEGER):INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION U14StrToLongs(lpszBuff:PChar;palNums:TpNums;
                                sMaxLongs:INTEGER):INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION U14LongsFrom1401(hand:INTEGER;palBuff:TpNums;
                                sMaxLongs:INTEGER):INTEGER;stdcall; EXTERNAL  'USE1432';

PROCEDURE U14SetTimeout(hand:INTEGER;lTimeout:LONGINT);    stdcall; EXTERNAL  'USE1432';
FUNCTION  U14GetTimeout(hand:INTEGER):LONGINT;             stdcall; EXTERNAL  'USE1432';
FUNCTION  U14OutBufSpace(hand:INTEGER):INTEGER;            stdcall; EXTERNAL  'USE1432';
FUNCTION  U14BaseAddr1401(hand:INTEGER):LONGINT;           stdcall; EXTERNAL  'USE1432';
FUNCTION  U14DriverVersion:LONGINT;                        stdcall; EXTERNAL  'USE1432';
FUNCTION  U14GetUserMemorySize(hand:INTEGER;VAR memorySize:LONGINT)
                                                  :INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION  U14KillIO1401(hand:INTEGER):INTEGER;             stdcall; EXTERNAL  'USE1432';
FUNCTION U14ZeroBlockCount(hand:INTEGER):INTEGER;          stdcall; EXTERNAL  'USE1432';
FUNCTION U14ByteCount(hand:INTEGER;VAR howMany:LONGINT):INTEGER;
                                                           stdcall; EXTERNAL  'USE1432';
FUNCTION U14BlkTransState(hand:INTEGER):INTEGER;           stdcall; EXTERNAL  'USE1432';
FUNCTION U14StopCircular(hand:INTEGER):INTEGER;            stdcall; EXTERNAL  'USE1432';
FUNCTION U14StateOf1401(hand:INTEGER):INTEGER;             stdcall; EXTERNAL  'USE1432';

FUNCTION U14Grab1401(hand:INTEGER):INTEGER;                stdcall; EXTERNAL  'USE1432';
FUNCTION U14Free1401(hand:INTEGER):INTEGER;                stdcall; EXTERNAL  'USE1432';
FUNCTION U14Step1401(hand:INTEGER):INTEGER;                stdcall; EXTERNAL  'USE1432';
FUNCTION U14StepTill1401(hand:INTEGER;steps:LONGINT;
                            targetAddress:LONGINT):INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION U14Registers1401(hand:INTEGER;
                             VAR csBlock:TCSBlock):INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION U14Set1401Registers(hand:INTEGER;
                           CONST csBlock:TCSBlock):INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION U14SetOrin(hand:INTEGER;sOrIn:INTEGER):INTEGER;   stdcall; EXTERNAL  'USE1432';

(*Windows specific*)
FUNCTION U14CallDriver(hand:INTEGER;bMainFn:BYTE;bSubFn:BYTE;
                               lpParams:TU14Param):INTEGER;stdcall; EXTERNAL  'USE1432';

FUNCTION U14RegCallBackWnd(n1401:INTEGER;hWnd:HWND;
                               lpwMessCode:TPWORD):INTEGER;stdcall; EXTERNAL  'USE1432';
FUNCTION U14DeRegCallBackWnd(hWnd:HWND):INTEGER;           stdcall; EXTERNAL  'USE1432';
FUNCTION U14GetMonBuff(lpBuffer:PChar;
                               wMaxLen:WORD):INTEGER;      stdcall; EXTERNAL  'USE1432';
FUNCTION U14GetCircSelector:INTEGER;                       stdcall; EXTERNAL  'USE1432';

FUNCTION U14GetTransfer(hand:INTEGER;VAR transBlock:TGet_TX_Block)
                                                  :INTEGER;stdcall; EXTERNAL  'USE1432';

FUNCTION U14Status1401(hand:INTEGER;bMainFn:BYTE;lpParams:TU14Param):INTEGER;
{optional way of calling driver routine when using "Control" main functions,
 in order to create clearer code}
BEGIN
U14CallDriver(hand,bMainFn,U14_NOSUBFN,lpParams);
END;

FUNCTION U14Control1401(hand:INTEGER;bMainFn:BYTE;lpParams:TU14Param):INTEGER;
{Optional way of calling driver routine when using "Control" main functions,
 in order to create clearer code}
BEGIN
U14CallDriver(hand,bMainFn,U14_NOSUBFN,lpParams);
END;

END.


