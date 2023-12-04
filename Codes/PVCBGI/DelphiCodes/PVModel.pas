unit PVModel;

interface

Uses Dynamics, ucomplex, ParserDel, Command, GeneratorVars;

 Const
      NumProperties = 15;
      NumVariables = 14;

{$INCLUDE DSSCallBackStructDef.pas}

Type

   TSymCompArray = Array[0..2] of Complex;

   pTDynamicsRec =  ^TDynamicsRec;
   pTGeneratorVars = ^TGeneratorVars;
//   pTDynaCallBacks = ^TDynaCallBacks;


   TPVModel = class(TObject)
   private
        RS, LS,
        {Power outer loop}
        Pref, Fref, kFP, TcFP,//F-P droop curve coefficiencies
        DetPinv_out, DetPinv_outn, //Input and output of the time delay block of the F-P droop
        Qref, Vref, kVQ, TcVQ,//V-Q droop curve coefficiencies
        DetQinv_out, DetQinv_outn, //Input and output of the time delay block of the V-Q droop
        Pgrid, Qgrid,//Output active and reactive power from the inverter to the grid

        {Virtual synchronous generator controller}
        Vinertia, Vdamp,//Virtual inertia and damping factor
        Omega_grid,//Angle velocities/frequencies of the inverter and grid
        DetOmega, DetOmegan,//Change of Angle velocities/frequencies of inverter
        Theta_est, Theta_estn,//Estimated Theta

        {Voltage PI controller}
        Kp, Ki//PI controller coefficiencies

        //{PLL}
        //KcPLL, TcPLL, int_PLL, int_PLLn,//PLL PI coefficiencies and integration value
        :Double;

        InDynamics:Boolean;

        {Power grid}
        Va, Vb, Vc,
        Ia, Ib, Ic//Three phase voltage and current of power grid
        :Complex;

        {Inverter}
        Ea, Eb, Ec,
        Ean, Ebn, Ecn
        :Double;//Inverter terminal voltage
        Iinva, Iinvb, Iinvc,
        Iinvan, Iinvbn, Iinvcn
        :Complex;//Inverter terminal current

        {Variables for dynamics}
        dDetPinv_out, dDetPinv_outn,
        dDetQinv_out, dDetQinv_outn,
        dDetOmega, dDetOmegan,
        //dint_PLL, dint_PLLn,
        dTheta_est, dTheta_estn,
        dEa, dEb, dEc,
        dEan, dEbn, dEcn
        :Double;
        dIinva, dIinvan,
        dIinvb, dIinvbn,
        dIinvc, dIinvcn:Complex;

        FirstIteration, FixedSlip:Boolean;

      TraceFile:TextFile;

      //Procedure ParkTrans(Const Va, Vb, Vc, Ia, Ib, Ic:Complex);
      //Procedure DoPLL(Const Va, Vb, Vc:Complex);
      //Procedure FPdroop(Const V:Complex);
      //Procedure VQdroop(Const V:Complex);
      Procedure DoHelpCmd;
      function Get_Variable(i: Integer): Double;
      procedure Set_Variable(i: Integer; const Value: Double);

      Procedure InitTraceFile;         //Creating a trace file for debug
      Procedure WriteTraceRecord;      //Writing into the trace file

   protected

   public

        DynaData: pTDynamicsRec;
        PVData:  pTGeneratorVars;
        CallBack: pDSSCallBacks;

     Procedure Init(Var Vabc, Iabc:TSymCompArray);
     Procedure Edit;  // Uses ModelParser
     Procedure Integrate;
     Procedure CalcDynamic(Var Vabc, Iabc:TSymCompArray);
     Procedure CalcPFlow(Var Vabc, Iabc:TSymCompArray);
     Procedure ReCalcElementData;
     Procedure InterpretOption(s:String);

     Property Variable[i:Integer]:Double Read Get_Variable Write Set_Variable;

     constructor Create(Var PVVars:TGeneratorVars; Var DynaVars:TDynamicsRec; Var CallBacks:TDSSCallBacks);
     destructor Destroy; override;

   end;

Var

   ActiveModel:TPVModel;
   ModelParser:TParser;
   CommandList:TCommandlist;

implementation

Uses SysUtils;
{-------------------------------------------------------------------------------------------------------------}
{Model Class code}
{-------------------------------------------------------------------------------------------------------------}

{ TIndMach012Model }

Var DebugTrace:Boolean;

{-------------------------------------------------------------------------------------------------------------}
constructor TPVModel.Create(Var PVVars:TGeneratorVars; Var DynaVars:TDynamicsRec; Var CallBacks:TDSSCallBacks);
{-------------------------------------------------------------------------------------------------------------}
begin
      RS := 1;
      LS := 1;
{F-P droop controller}
      Pref := 400000;
      Fref := 60;
      kFP := 0.00001;
      TcFP := 0.1;
{V-Q droop controller}
      Qref := 200000;
      Vref := 277;
      kVQ := 0.0001;
      TcVQ := 0.1;
{VSG controller}
      Vinertia := 0.5;
      Vdamp := 20;
      Omega_grid := Fref * 2 * Pi;
{Voltage PI controller}
      Kp := 1;
      Ki := 1;

      PVData := @PVVars;  // Make pointer to data in main DSS
      DynaData := @DynaVars;
      CallBack := @CallBacks;
      {With PVData^ do
      begin
        RS := 1;
        LS := 1;
      end;}

      InDynamics := FALSE;

      RecalcElementData;


end;

destructor TPVModel.Destroy;
begin

  inherited;

end;

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.Edit;
{-------------------------------------------------------------------------------------------------------------}

VAR
   ParamPointer:Integer;
   ParamName:String;
   Param:String;

begin
{This DLL has a version of the DSS Parser compiled into it directly because it
 was written on the same platform as the DSS. Otherwise, one should use the Callbacks.}

     ParamPointer := 0;
     ParamName := ModelParser.NextParam;
     Param := ModelParser.StrValue;
     WHILE Length(Param)>0 DO BEGIN
         IF Length(ParamName) = 0 THEN Begin
           If Comparetext(Param, 'help')=0 then ParamPointer := 10 Else Inc(ParamPointer);
         End
         ELSE ParamPointer := CommandList.GetCommand(ParamName);

         CASE ParamPointer OF
           // 0: DoSimpleMsg('Unknown parameter "'+ParamName+'" for Object "'+Name+'"');
            1: Pref := ModelParser.DblValue;
            2: Fref := ModelParser.DblValue;
            3: kFP := ModelParser.DblValue;
            4: TcFP := ModelParser.DblValue;
            5: Qref := ModelParser.DblValue;
            6: Vref := ModelParser.DblValue;
            7: kVQ := ModelParser.DblValue;
            8: TcVQ := ModelParser.DblValue;
            9: Vinertia := ModelParser.DblValue;
            10: Vdamp := ModelParser.DblValue;
            11: Omega_grid := ModelParser.DblValue;
            12: Kp := ModelParser.DblValue;
            13: Ki := ModelParser.DblValue;
            14: InterpretOption(ModelParser.StrValue);
            15: DoHelpCmd;     // whatever the option, do help
         ELSE
         END;

         ParamName := ModelParser.NextParam;
         Param := ModelParser.StrValue;
     END;

     RecalcElementData;

end;

{-------------------------------------------------------------------------------------------------------------}

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.Init(Var Vabc, Iabc:TSymCompArray);
{-------------------------------------------------------------------------------------------------------------}

// Init for Dynamics mode

begin
   Va := Vabc[0];   // Save for variable calcs
   Vb := Vabc[1];
   Vc := Vabc[2];
   Ia := Iabc[0];
   Ib := Iabc[1];
   Ic := Iabc[2];
   {RecalcElementData ;????}
   // Compute Voltage behind transient reactance and set derivatives to zero
   DetPinv_out := 0.0;
   dDetPinv_out := 0.0;
   DetPinv_outn := DetPinv_out;
   dDetPinv_outn := dDetPinv_out;
   DetQinv_out := 0.0;
   dDetQinv_out := 0.0;
   DetQinv_outn := DetQinv_out;
   dDetQinv_outn := dDetQinv_out;
   Pgrid := cadd(cmul(Va, conjg(Ia)), cadd(cmul(Vb, conjg(Ib)), cmul(Vc, conjg(Ic)))).RE;
   Qgrid := cadd(cmul(Va, conjg(Ia)), cadd(cmul(Vb, conjg(Ib)), cmul(Vc, conjg(Ic)))).IM;
   DetOmega := 0.0;
   dDetOmega := 0.0;
   DetOmegan := DetOmega;
   dDetOmegan := dDetOmega;
   Theta_est := cang(Va);
   dTheta_est := 0.0;
   Theta_estn := Theta_est;
   dTheta_estn := dTheta_est;
   Ea := cabs(Va);
   dEa := 0.0;
   Ean := Ea;
   dEan := dEa;
   Eb := cabs(Vb);
   dEb := 0.0;
   Ebn := Eb;
   dEbn := dEb;
   Ec := cabs(Vc);
   dEc := 0.0;
   Ecn := Ec;
   dEcn := dEc;
   Iinva := Ia;
   dIinva := czero;
   Iinvan := Iinva;
   dIinvan := dIinva;
   Iinvb := Ib;
   dIinvb := czero;
   Iinvbn := Iinvb;
   dIinvbn := dIinvb;
   Iinvc := Ic;
   dIinvc := czero;
   Iinvcn := Iinvc;
   dIinvcn := dIinvc;
end;

{-------------------------------------------------------------------------------------------------------------}
//procedure TPVModel.ParkTrans(Const Va, Vb, Vc, Ia, Ib, Ic:Complex);
//Vd := ;
//Vq := ;
//Id := ;
//Iq := ;

{-------------------------------------------------------------------------------------------------------------}
//procedure TPVModel.DoPLL(Const Vq:Double);
//begin
//  Omega_inv := (int_PLL - Vq)*KcPLL;
//end;
{-------------------------------------------------------------------------------------------------------------}

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.ReCalcElementData;
{-------------------------------------------------------------------------------------------------------------}
begin
    Ea := 0.0;
    Eb := 0.0;
    Ec := 0.0;
    Iinva := CZERO;
    Iinvb := CZERO;
    Iinvc := CZERO;
    with PVData^ do
    begin
      Zthev.re := 1000;
      Zthev.im := 1000;
    end;

    FirstIteration := True;

    If DebugTrace Then InitTraceFile;
end;

procedure TPVModel.InterpretOption(s: String);
{-------------------------------------------------------------------------------------------------------------}
begin
     Case Uppercase(s)[1] of
       'F': Fixedslip := TRUE;
       'V': Fixedslip := FALSE;
       'D': DebugTrace := TRUE;   // DEBUG
       'N': DebugTrace := FALSE;  // NODEBUG
     Else

     End;
end;

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.CalcDynamic(var Vabc, Iabc: TSymCompArray);
{-------------------------------------------------------------------------------------------------------------}
begin
       Va := Vabc[0];   // Save for variable calcs
       Vb := Vabc[1];
       Vc := Vabc[2];
       //Ia := Iabc[0];
       //Ib := Iabc[1];
       //Ic := Iabc[2];
       Pgrid := cadd(cmul(Va, conjg(Iinva)), cadd(cmul(Vb, conjg(Iinvb)), cmul(Vc, conjg(Iinvc)))).RE;
       Qgrid := cadd(cmul(Va, conjg(Iinva)), cadd(cmul(Vb, conjg(Iinvb)), cmul(Vc, conjg(Iinvc)))).IM;
       //Pgrid := cadd(cmul(PCLX(Ea, Theta_est), conjg(Iinva)), cadd(cmul(PCLX(Eb, Theta_est - 2 * Pi / 3), conjg(Iinvb)), cmul(PCLX(Ec, Theta_est + 2 * Pi / 3), conjg(Iinvc)))).RE;
       //Qgrid := cadd(cmul(PCLX(Ea, Theta_est), conjg(Iinva)), cadd(cmul(PCLX(Eb, Theta_est - 2 * Pi / 3), conjg(Iinvb)), cmul(PCLX(Ec, Theta_est + 2 * Pi / 3), conjg(Iinvc)))).IM;
       {Theta_est := cang(Va);
       Ea := cabs(Va);
       Eb := cabs(Vb);
       Ec := cabs(Vc);
       Iinva := Ia;
       Iinvb := Ib;
       Iinvc := Ic;}
       InDynamics := TRUE;
       Iabc[0] := Iinva;    // Save for variable calcs
       Iabc[1] := Iinvb;
       Iabc[2] := Iinvc;

       If DebugTrace Then WriteTraceRecord;

end;

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.Integrate;
{-------------------------------------------------------------------------------------------------------------}

Var  h2:double;

begin

    If DynaData^.IterationFlag =0 Then Begin  // on predictor step
        DetPinv_outn := DetPinv_out;            // update old values
        dDetPinv_outn := dDetPinv_out;
        DetQinv_outn := DetQinv_out;
        dDetQinv_outn := dDetQinv_out;
        DetOmegan := DetOmega;
        dDetOmegan := dDetOmega;
        Theta_estn := Theta_est;
        dTheta_estn := dTheta_est;
        Ean := Ea;
        dEan := dEa;
        Ebn := Eb;
        dEbn := dEb;
        Ecn := Ec;
        dEcn := dEc;
        Iinvan := Iinva;
        dIinvan := dIinva;
        Iinvbn := Iinvb;
        dIinvbn := dIinvb;
        Iinvcn := Iinvc;
        dIinvcn := dIinvc;
    End;
   // Derivative of PLL
    //dint_PLL := Vq/TcPLL;
    //dTheta_est := (Omega_inv - Omega_grid);
   // Derivative of FPdroop
    dDetPinv_out := (-DetOmega / kFP - DetPinv_out) / TcFP;
   // Derivative of VQdroop
    dDetQinv_out := ((Vref - Ea) / kVQ - DetQinv_out) / TcVQ;
   // Derivative of VSG
    dDetOmega := (Pref + DetPinv_out - Pgrid) / Vinertia / Omega_grid - Vdamp * DetOmega / Vinertia;
    dTheta_est := DetOmega + Omega_grid;
   // Derivative of Voltage
    dEa := (Qref + DetQinv_out - Qgrid) * Kp / Ki;
    dEb := (Qref + DetQinv_out - Qgrid) * Kp / Ki;
    dEc := (Qref + DetQinv_out - Qgrid) * Kp / Ki;
   // Derivative of Inverter
   //With InvData^ Do
   //Begin
    //dIinva := Cadd(Cmulreal(Iinva, -RS / LS), Cdivreal(Csub(PCLX(Ea, Theta_est), Va), LS));
    //dIinvb := Cadd(Cmulreal(Iinvb, -RS / LS), Cdivreal(Csub(PCLX(Eb, Theta_est - 2 * Pi / 3), Vb), LS));
    //dIinvc := Cadd(Cmulreal(Iinvc, -RS / LS), Cdivreal(Csub(PCLX(Ec, Theta_est + 2 * Pi / 3), Vc), LS));
   //End;
    {With PVData^ do
    begin
    dIinva := Cadd(Cmulreal(Iinva, -RS / LS), Cdivreal(Csub(PCLX(Ea, Theta_est), Va), LS));
    dIinvb := Cadd(Cmulreal(Iinvb, -RS / LS), Cdivreal(Csub(PCLX(Eb, Theta_est - 2 * Pi / 3), Vb), LS));
    dIinvc := Cadd(Cmulreal(Iinvc, -RS / LS), Cdivreal(Csub(PCLX(Ec, Theta_est + 2 * Pi / 3), Vc), LS));
    end;}
    dIinva := Cadd(Cmulreal(Iinva, -RS / LS), Cdivreal(Csub(PCLX(Ea, Theta_est), Va), LS));
    dIinvb := Cadd(Cmulreal(Iinvb, -RS / LS), Cdivreal(Csub(PCLX(Eb, Theta_est - 2 * Pi / 3), Vb), LS));
    dIinvc := Cadd(Cmulreal(Iinvc, -RS / LS), Cdivreal(Csub(PCLX(Ec, Theta_est + 2 * Pi / 3), Vc), LS));





    // Trapezoidal Integration
    h2 :=  Dynadata^.h*0.5;
    //int_PLL := int_PLLn + (dint_PLL + dint_PLLn)*h2;
    //Theta_est := Theta_estn + (dTheta_est + dTheta_estn)*h2;
    DetPinv_out := DetPinv_outn + (dDetPinv_out + dDetPinv_outn) * h2;
    DetQinv_out := DetQinv_outn + (dDetQinv_out + dDetQinv_outn) * h2;
    DetOmega := DetOmegan + (dDetOmega + dDetOmegan) * h2;
    Theta_est := Theta_estn + (dTheta_est + dTheta_estn) * h2;
    Ea := Ean + (dEa + dEan) * h2;
    Eb := Ebn + (dEb + dEbn) * h2;
    Ec := Ecn + (dEc + dEcn) * h2;
    Iinva := Cadd(Iinvan, CmulReal(Cadd(dIinva, dIinvan), h2));
    Iinvb := Cadd(Iinvbn, CmulReal(Cadd(dIinvb, dIinvbn), h2));
    Iinvc := Cadd(Iinvcn, CmulReal(Cadd(dIinvc, dIinvcn), h2));



end;

{-------------------------------------------------------------------------------------------------------------}

{-------------------------------------------------------------------------------------------------------------}

{-------------------------------------------------------------------------------------------------------------}
PROCEDURE TPVModel.DoHelpCmd;
{-------------------------------------------------------------------------------------------------------------}

Var
    HelpStr: String;
    AnsiHelpStr: AnsiString;
    CRLF: String;

Begin

    CRLF := #13#10;
    HelpStr := 'Pref= Active power at reference frequency.'+CRLF;
    HelpStr := HelpStr + 'Fref= Reference frequency of the power grid.' + CRLF;
    HelpStr := HelpStr + 'kFP= Slop of the F-P droop curve.' + CRLF;
    HelpStr := HelpStr + 'TcFP= Time delay coefficiency of F-P.' + CRLF;
    HelpStr := HelpStr + 'Qref= Reactive power at reference voltage.'+CRLF;
    HelpStr := HelpStr + 'Vref= Reference voltage of the power grid.' + CRLF;
    HelpStr := HelpStr + 'kVQ= Slop of the V-Q droop curve.' + CRLF;
    HelpStr := HelpStr + 'TcVQ= Time delay coefficiency of V-Q.' + CRLF;
    HelpStr := HelpStr + 'Vinertia= Virtual inertia of the inverter.' + CRLF;
    HelpStr := HelpStr + 'Vdamp= Virtual damp of the inverter.' + CRLF;
    HelpStr := HelpStr + 'Omega_grid= Angular speed of the power grid.' + CRLF;
    HelpStr := HelpStr + 'Kp= Proportional coefficiency of voltage PI controller' + CRLF;
    HelpStr := HelpStr + 'Ki= Integratial coefficiency of voltage PI controller.' + CRLF;
    HelpStr := HelpStr + 'option={fixedslip | variableslip | Debug | NoDebug }' + CRLF;
    HelpStr := HelpStr + 'Help: this help message.';

    AnsiHelpStr := HelpStr;    // Implicit typecast

    {All strings between OpenDSS and DLLs are AnsiString}
    CallBack^.MsgCallBack(pAnsichar(AnsiHelpStr), Length(HelpStr));

End;

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.CalcPFlow(var Vabc, Iabc: TSymCompArray);
{-------------------------------------------------------------------------------------------------------------}
begin
    // By default do nothing

end;
{-------------------------------------------------------------------------------------------------------------}
function TPVModel.Get_Variable(i: Integer): Double;
{-------------------------------------------------------------------------------------------------------------}
begin

     Result := -1.0;
    Case i of

      1: Result := DetOmega + Omega_grid;
      2: Result := dDetOmega;
      3: Result := Theta_est;
      4: Result := dTheta_est;
      5: Result := Ea;
      6: Result := dEa;
      7: Result := Pref + DetPinv_out;
      8: Result := Qref + DetQinv_out;
      9: Result := Pgrid;
     10: Result := Qgrid;
     11: Result := cabs(Iinva);
     12: Result := cabs(dIinva);
     13: Result := cabs(Va);
     14: Result := cabs(Ia);
     //15: Result := cabs(Iinvc);
     //16: Result := cabs(dIinvc);
    Else

    End;

end;

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.Set_Variable(i: Integer; const Value: Double);
{-------------------------------------------------------------------------------------------------------------}
begin
      Case i of

      1:  kFP:= Value;
      2:  TcFP:= Value;
      3:  kVQ:= Value;
      4:  TcVQ:= Value;
      5:  Kp:= Value;
      6:  Ki:= Value;

    Else
        {Do Nothing for other variables: they are read only}
        {Or should I say they are not presetable parameters but calculated variables.}
    End;
end;

{The following codes are responisble for debug. Normally those would not be
 executed due to the initail FALSE value to Debugtrace.}

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.InitTraceFile;
{-------------------------------------------------------------------------------------------------------------}
begin

     AssignFile(TraceFile, 'PVModel_Trace.CSV');
     Rewrite(TraceFile);

     Write(TraceFile, 'Time, Iteration, DetOmega, Theta_est, Ea, dEa, Eb, dEb, Ec, dEc, |Iinva|');
     Writeln(TraceFile);

     CloseFile(TraceFile);
end;

{-------------------------------------------------------------------------------------------------------------}
procedure TPVModel.WriteTraceRecord;
{-------------------------------------------------------------------------------------------------------------}
begin
      AssignFile(TraceFile, 'PVModel_Trace.CSV');
      Append(TraceFile);
      Write(TraceFile, Format('%-.6g, ',[DynaData^.t]), DynaData^.IterationFlag,', ', Format('%-.6g, ',[DetOmega]));

      Write(TraceFile, Format('%-.6g, %-.6g, ', [Theta_est, Ea]));
      Write(TraceFile, Format('%-.6g, %-.6g, %-.6g, %-.6g, ', [dEa, Eb, dEb, Ec]));
      Write(TraceFile, Format('%-.6g, %-.6g, ', [dEc, Cabs(Iinva)]));

      Writeln(TraceFile);

      CloseFile(TraceFile);
end;

initialization

Debugtrace := FALSE;

end.
