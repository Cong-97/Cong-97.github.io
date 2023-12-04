library PVCB;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  MainUnit in 'MainUnit.pas',
  Arraydef in 'Arraydef.pas',
  Dynamics in 'Dynamics.pas',
  Command in 'Command.pas',
  mathutil in 'mathutil.pas',
  HashList in 'HashList.pas',
  Ucmatrix in 'Ucmatrix.pas',
  PVModel in 'PVModel.pas',
  RPN in 'RPN.pas',
  Ucomplex in 'Ucomplex.pas',
  ParserDel in 'ParserDel.pas',
  GeneratorVars in 'GeneratorVars.pas';

// Special version of ParserDel

Exports

     New,
     Delete,
     Select,

     Init,
     Calc,
     Integrate,
     Save,
     Restore,
     Edit,
     UpdateModel,

     NumVars,
     GetAllVars,
     GetVariable,
     SetVariable,
     GetVarName;

{$R *.RES}

begin

end.
