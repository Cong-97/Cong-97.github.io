unit MainUnit;

{ Definition of DLL interface functions for user-written Generator models in the DSS }

{Dynamics algorithm revised 7-18-04 to go to Thevinen equivalent}

interface
Uses Ucomplex, Arraydef, Dynamics, PVModel, GeneratorVars;


  {Imports Generator Variables Structures and DSS structures from Dynamics}

    {Note: everything is passed by reference (as a pointer), so it is possible to change the values in
     the structures (imported in Dynamics) in the main program.  This is dangerous so be careful.}

    Function    New(Var PVVars:TGeneratorVars; Var DynaData:TDynamicsRec; Var CallBacks:TDSSCallBacks): Integer;  Stdcall; // Make a new instance
    Procedure   Delete(var ID:Integer); Stdcall;  // deletes specified instance
    Function    Select(var ID:Integer):Integer; Stdcall;    // Select active instance

    Procedure   Init(V, I:pComplexArray);Stdcall;
                  {Initialize model.  Called when entering Dynamics mode.
                   V,I should contain results of most recent power flow solution.}
    Procedure   Calc(V, I:pComplexArray); stdcall;
                  {Main routine for performing the model calculations.  For "usermodel", this
                   function basically computes I given V.  For "shaftmodel", uses V and I
                   to calculate Pshaft, speed, etc. in dynamic data structures}
    Procedure   Integrate; stdcall; // Integrates any state vars
                  {Called to integrate state variables. User model is responsible for its own
                   integration. Check IterationFlag to determine if this
                   is a predictor or corrector step  }
    Procedure   Edit(s:pAnsichar; Maxlen:Cardinal); Stdcall;
                  {called when DSS encounters user-supplied data string.  This module
                   is reponsible for interpreting whatever format this user-written modeli
                   is designed for.}
    Procedure   UpdateModel; StdCall;
                  {This is called when DSS needs to update the data that is computed
                   from user-supplied data forms.  }
    Procedure   Save; Stdcall;
                  {Save the model to a file (of the programmer's choice) so that the state
                   data, if any can be restored for a  restart.}
    Procedure   Restore; Stdcall;
                  {Reverse the Save command}

    {The user may return a number of double-precision values for monitoring}
    Function    NumVars:Integer;Stdcall;   // Number of variables that can be returned for monitoring
    Procedure   GetAllVars(Vars:pDoubleArray);StdCall;
                  {Called by DSS monitoring elements.  Returns values of all monitoring variables in
                   an array of doubles.  The DSS will allocate "Vars" to the appropriate size.  This
                   routine will use Vars as a pointer to the array.}
    Function    GetVariable(var i:Integer):double;StdCall;   // returns a i-th variable value  only
    Procedure   SetVariable(var i:Integer;var  value:Double); StdCall;
                  {DSS allows users to set variables of user-written models directly.
                   Whatever variables that are exposed can be set if this routine handles it}
    Procedure   GetVarName(var VarNum:Integer;  VarName:pAnsiChar; maxlen:Cardinal); StdCall;
                   {Returns name of a specific variable as a pointer to a string.
                    Set VarName= pointer to the first character in a null-terminated string}

implementation

Uses  Classes, Sysutils, ParserDel, Command, MathUtil;




// Keeping track of the models
Var
     ModelList:Tlist;

     

     PropertyName:Array[1..NumProperties] of String;

{-------------------------------------------------------------------------------------------------------------}
{DLL Interface Routines}
{-------------------------------------------------------------------------------------------------------------}

Function  New(Var PVVars:TGeneratorVars; Var DynaData:TDynamicsRec; Var CallBacks:TDSSCallBacks): Integer;  Stdcall;// Make a new instance
Begin
    ActiveModel := TPVModel.Create(PVVars, DynaData, CallBacks);
    Result := ModelList.Add(ActiveModel)+1;
End;

Procedure Delete(var ID:Integer); Stdcall;  // deletes specified instance
Begin
     If ID <= ModelList.Count Then Begin
        ActiveModel := ModelList.Items[ID-1];
        If ActiveModel <> Nil then ActiveModel.Free;
        ActiveModel := Nil;
        ModelList.Items[ID-1] := Nil;
     End;
End;

Procedure DisposeModels;
Var i:Integer;
Begin
     For i := 1 to ModelList.Count Do
      Begin
        ActiveModel := ModelList.Items[i-1];
        ActiveModel.Free;
      End;
End;


Function  Select(var ID:Integer):Integer; Stdcall;    // Select active instance
Begin
     Result := 0;
     If ID <= ModelList.Count Then Begin
        ActiveModel := ModelList.Items[ID-1];
        If ActiveModel <> Nil Then Result := ID;
     End;
End;


procedure Init(V, I:pComplexArray);Stdcall;   // For Dynamics Mode

Var
    Vabc, Iabc:TSymCompArray;
    j:Integer;
Begin

    If ActiveModel <> Nil Then
    Begin
    for j := 1 to 3 do begin
     Vabc[j - 1] := V^[j];
     Iabc[j - 1] := I^[j];
    end;
     ActiveModel.Init(Vabc, Iabc);
    End;

End;

Procedure  Calc(V, I:pComplexArray); stdcall; // returns voltage or torque
{
 Perform calculations related to model
   Typically, Electrical model will compute I given V
   Machine dynamics may change andy of the GenVars (typically shaft power)
   You can change any of the variables, including the solution time variables, which could be dangerous.
   BE CAREFUL!
}

Var
    Vabc, Iabc:TSymCompArray;
    j:Integer;


Begin

  If ActiveModel <> Nil Then
   Begin
   for j := 1 to 3 do begin
     Vabc[j - 1] := V^[j];
     Iabc[j - 1] := I^[j];
   end;
    // compute Iabc
       With ActiveModel Do
         Begin
           Case DynaData^.SolutionMode of
               DYNAMICMODE: Begin
                              CalcDynamic(Vabc, Iabc);
                            End;
           Else  {All other modes are power flow modes}
                 Begin
                    CalcPflow(Vabc, Iabc);
                 End;
           End;
         End;

   for j := 1 to 3 do I^[j] := Iabc[j - 1];
   End;

End;


Procedure Integrate; stdcall; // Integrates any Var vars
Begin

  If ActiveModel <> Nil Then  ActiveModel.Integrate;

End;

Procedure Save; Stdcall;
{Save the states to a disk file so that the solution can be restarted from this point in time}
Begin

  If ActiveModel <> Nil Then
    Begin



    End;

End;

Procedure Restore; Stdcall;
Begin

  If ActiveModel <> Nil Then
    Begin



    End;

End;

PROCEDURE DefineProperties;

Begin

     // Define Property names
     PropertyName[1] := 'Pref';
     PropertyName[2] := 'Fref';
     PropertyName[3] := 'kFP';
     PropertyName[4] := 'TcFP';
     PropertyName[5] := 'Qref';
     PropertyName[6] := 'Vref';
     PropertyName[7] := 'kVQ';
     PropertyName[8] := 'TcVQ';
     PropertyName[9] := 'Vinertia';
     PropertyName[10] := 'Vdamp';
     PropertyName[11] := 'Omega_grid';
     PropertyName[12] := 'Kp';
     PropertyName[13] := 'Ki';
     PropertyName[14] := 'option';
     PropertyName[15] := 'help';

     CommandList := TCommandList.Create(Slice(PropertyName, NumProperties));
     CommandList.Abbrev := TRUE;
End;


Procedure DisposeProperties;
Var
   i:Integer;
Begin
    For i := 1 to NumProperties Do PropertyName[i] := '';
    CommandList.Free;
End;

Procedure Edit(s:pAnsichar; Maxlen:Cardinal); Stdcall; // receive string from OpenDSS to handle

Begin

  If ActiveModel <> Nil Then
    Begin
      ModelParser.CmdString := S;  // Load up Parser
      ActiveModel.Edit;     {Interpret string}
    End;

End;

Procedure   UpdateModel; StdCall;

Begin
    If ActiveModel <> Nil then ActiveModel.RecalcElementData;
End;


Function NumVars:Integer; Stdcall;
{Return the number of Vars to be used for monitoring}
Begin
    Result := NumVariables;
End;

Procedure GetAllVars(Vars:pDoubleArray);StdCall;
{Fill in the States array for monitoring}

{The Vars array has been allocated by the calling program}
Var i,j:Integer;

Begin

  Try
   IF Vars <> NIL Then
     Begin
       For i := 1 to NumVariables Do Begin
        j:=i;
        Vars^[i] := GetVariable(j);
       End;
     End;
  Except
     On E:Exception Do
       Begin
         {Oops, there has been an error, probably Vars not allocated right
          or we overflowed the array}
       End;
  End
End;

Function    GetVariable(var i:Integer):double;StdCall;   // get a particular variable

Begin
    Result := ActiveModel.Variable[i];
End;

Procedure   SetVariable(var i:Integer;var  value:Double); StdCall;
Begin
    ActiveModel.Variable[i] := Value;
End;


Procedure   GetVarName(var VarNum:Integer;  VarName:pAnsichar; MaxLen:Cardinal);
{Return the name of a Var as a pointer to a null terminated string}
Begin

     CASE VarNum of
         1: StrLCopy(VarName , 'Omega_inv', Maxlen);  // Return a pointer to this string constant
         2: StrLCopy(VarName , 'dOmega_inv', maxlen);
         3: StrLCopy(VarName , 'Theta', maxlen);
         4: StrLCopy(VarName , 'dTheta', maxlen);
         5: StrLCopy(VarName , 'Ea', maxlen);
         6: StrLCopy(VarName , 'dEa', maxlen);
         7: StrLCopy(VarName , 'Pinv', maxlen);
         8: StrLCopy(VarName , 'Qinv', maxlen);
         9: StrLCopy(VarName , 'Pgrid', maxlen);
        10: StrLCopy(VarName , 'Qgrid', maxlen);
        11: StrLCopy(VarName , 'Iinva', maxlen);
        12: StrLCopy(VarName , 'dIinva', maxlen);
        13: StrLCopy(VarName , 'Va', maxlen);
        14: StrLCopy(VarName , 'Ia', maxlen);
     ELSE

     END;

End;


initialization

   ModelList := Tlist.Create;
   ModelParser := TParser.Create;
   DefineProperties;

finalization

   DisposeModels;
   ModelList.Free;
   ModelParser.Free;
   DisposeProperties;

end.
