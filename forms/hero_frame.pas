{ This file is a part of Map editor for VCMI project

  Copyright (C) 2015-2016 Alexander Shishkin alexvins@users.sourceforge.net

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
unit hero_frame;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, FileUtil, strutils, typinfo, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ComboEx, EditBtn, ComCtrls, base_options_frame,
  gui_helpers, object_options, editor_consts, editor_types, base_info,
  lists_manager, editor_rtti, editor_classes, Map, LCLType, ExtCtrls, Spin,
  rttiutils;

type

  { THeroFrame }

  THeroFrame = class(TBaseOptionsFrame)
    cbName: TCheckBox;
    cbSex: TCheckBox;
    cbPortrait: TCheckBox;
    cbExperience: TCheckBox;
    cbBiography: TCheckBox;
    cbSkills: TCheckBox;
    AvailableFor: TCheckGroup;
    edBiography: TMemo;
    edSex: TComboBox;
    edPatrol: TComboBox;
    edHeroClass: TComboBox;
    edExperience: TEdit;
    edName: TEdit;
    edPortrait: TComboBoxEx;
    edOwner: TComboBox;
    edType: TComboBox;
    Label1: TLabel;
    AvailableForLabel: TLabel;
    AvailableForPlaceholder: TLabel;
    lbAttack: TLabel;
    lbDefence: TLabel;
    lbSpellPower: TLabel;
    lbKnowledge: TLabel;
    lbPatrol: TLabel;
    lbBiography: TLabel;
    lbSex: TLabel;
    lbName: TLabel;
    lbExperience: TLabel;
    lbPortrait: TLabel;
    lbHeroClass: TLabel;
    lbOwner: TLabel;
    pnSkills: TPanel;
    Placeholder1: TLabel;
    lbType: TLabel;
    Placeholder2: TLabel;
    Placeholder3: TLabel;
    Placeholder5: TLabel;
    Attack: TSpinEdit;
    Defence: TSpinEdit;
    SpellPower: TSpinEdit;
    Knowledge: TSpinEdit;
    procedure cbBiographyChange(Sender: TObject);
    procedure cbExperienceChange(Sender: TObject);
    procedure cbNameChange(Sender: TObject);
    procedure cbPortraitChange(Sender: TObject);
    procedure cbSexChange(Sender: TObject);
    procedure cbSkillsChange(Sender: TObject);
    procedure CustomiseChange(Sender: TObject);
    procedure edNameEditingDone(Sender: TObject);
    procedure edPatrolKeyPress(Sender: TObject; var Key: char);
    procedure edSexChange(Sender: TObject);
  private
    FOptions: IEditableHeroInfo;
    FHeroOptions: THeroOptions;
    FHeroDefinition: THeroDefinition;

    procedure Load;
    procedure Save;

    procedure LoadAvilableFor;
    procedure SaveAvilableFor;

    procedure CommitHeroOptions;
    procedure CommitHeroDefinition;
  protected
    FCustomName: TLocalizedString;
    FCustomFemale: Boolean;
    FCustomBiography: TLocalizedString;

    FCustomSkills, FDefaultSkills, FClassSkills, FMapSkills:  THeroPrimarySkills;

    FHeroTypeDefaults, FHeroMapDefaults: IHeroInfo;

    function GetDefaultBiography: TLocalizedString;
    function GetDefaultName: TLocalizedString;
    function GetDefaultSex: THeroSex;

    procedure UpdateText(AControl: TCustomEdit; AFlag: TCustomCheckBox; ACustom: TLocalizedString; ADefault: TLocalizedString);


    procedure StashSkills;
    procedure LoadSkills;
    procedure ResetSkills;

  protected
    procedure UpdateControls(); override;
    procedure VisitNormalHero(AOptions: THeroOptions); override;
    procedure VisitRandomHero(AOptions: THeroOptions); override;
    procedure VisitPrison(AOptions: THeroOptions); override;

  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure Commit; override;

    procedure VisitHero(AOptions: THeroOptions); override;
    procedure VisitHeroDefinition(AOptions: THeroDefinition); override;
  end;

implementation

{$R *.lfm}

{ THeroFrame }

procedure THeroFrame.edNameEditingDone(Sender: TObject);
begin
  FCustomName := edName.Text;
end;

procedure THeroFrame.edPatrolKeyPress(Sender: TObject; var Key: char);
begin
  if not (key in DigitChars +[#8]) then
  begin
    Key:=#0;
  end;
end;

procedure THeroFrame.edSexChange(Sender: TObject);
begin
  case edSex.ItemIndex of
    0: FCustomFemale:=false;
    1: FCustomFemale:=true;
  end;
end;

procedure THeroFrame.Load;
begin
  cbBiography.Checked:=FOptions.GetBiography <> '';
  if cbBiography.Checked then
    FCustomBiography := FOptions.GetBiography()
  else
    FCustomBiography := GetDefaultBiography();
  cbBiographyChange(cbBiography);

  cbName.Checked:=FOptions.GetName <> '';
  if cbName.Checked then
    FCustomName := FOptions.GetName()
  else
    FCustomName:=GetDefaultName();
  cbNameChange(cbName);


  cbSkills.Checked:=not FOptions.GetPrimarySkills.IsDefault;
  if cbSkills.Checked then
  begin
    FCustomSkills.Assign(FOptions.GetPrimarySkills());
  end
  else
  begin
    FCustomSkills.Assign(FDefaultSkills);
  end;
  cbSkillsChange(cbSkills);


  cbSex.Checked:= FOptions.GetSex <> THeroSex.default;
  if cbSex.Checked then
    FCustomFemale := FOptions.GetSex = THeroSex.female
  else
    FCustomFemale := GetDefaultSex = THeroSex.female;
  cbSexChange(cbSex);

end;

procedure THeroFrame.Save;
begin
  if cbBiography.Checked then
  begin
    FOptions.SetBiography(edBiography.Text);
  end
  else
  begin
    FOptions.SetBiography('');
  end;


  if cbName.Checked then
  begin
    FOptions.SetName(edName.Text);
  end
  else begin
    FOptions.SetName('');
  end;

  if cbSex.Checked then
  begin
    FOptions.SetSex(THeroSex(Byte(edSex.ItemIndex)));
  end
  else begin
    FOptions.SetSex(THeroSex.default);
  end;

  if cbSkills.Checked then
  begin
    StashSkills;
    FOptions.GetPrimarySkills.Assign(FCustomSkills);
  end
  else
  begin
    FOptions.GetPrimarySkills.Clear;
  end;
end;

procedure THeroFrame.LoadAvilableFor;
var
  p: TPlayerColor;
begin
  for p in TPlayerColor do
  begin
    AvailableFor.Checked[Integer(p)] := FHeroDefinition.AvailableFor * [p] <> [];
  end;
end;

procedure THeroFrame.SaveAvilableFor;
var
  p: TPlayerColor;
  available_for: TPlayers;
begin
  available_for := [];
  for p in TPlayerColor do
  begin
    if AvailableFor.Checked[Integer(p)] then
      Include(available_for, p);
  end;
  FHeroDefinition.AvailableFor := available_for;
end;

procedure THeroFrame.CommitHeroOptions;
begin

end;

procedure THeroFrame.CommitHeroDefinition;
begin
  SaveAvilableFor;
end;

function THeroFrame.GetDefaultBiography: TLocalizedString;
begin
  if Assigned(FHeroMapDefaults) and (FHeroMapDefaults.GetBiography <> '') then
     FHeroMapDefaults.GetBiography()
  else if Assigned(FHeroTypeDefaults) then
    Result := FHeroTypeDefaults.GetBiography()
  else
    Result := '';
end;

function THeroFrame.GetDefaultName: TLocalizedString;
begin
  if Assigned(FHeroMapDefaults) and (FHeroMapDefaults.GetName <> '') then
     FHeroMapDefaults.GetName()
  else if Assigned(FHeroTypeDefaults) then
    Result := FHeroTypeDefaults.GetName()
  else
    Result := '';
end;

function THeroFrame.GetDefaultSex: THeroSex;
begin
  if Assigned(FHeroMapDefaults) and (FHeroMapDefaults.GetSex() <> THeroSex.default) then
     FHeroMapDefaults.GetSex()
  else if Assigned(FHeroTypeDefaults) then
    Result := FHeroTypeDefaults.GetSex()
  else
    Result := THeroSex.male;
end;

procedure THeroFrame.CustomiseChange(Sender: TObject);
begin
  UpdateControls();
end;

procedure THeroFrame.cbPortraitChange(Sender: TObject);
begin
  CustomiseChange(Sender);
end;

procedure THeroFrame.cbSexChange(Sender: TObject);
begin
  CustomiseChange(Sender);

  if cbSex.Checked then
  begin
    edSex.ItemIndex := Integer(FCustomFemale);
  end
  else
  begin
    edSex.ItemIndex := Integer(GetDefaultSex);
  end;
end;

procedure THeroFrame.cbSkillsChange(Sender: TObject);
begin
  CustomiseChange(Sender);
  if (Sender as TCheckBox).Checked then
  begin
    LoadSkills;
  end
  else
  begin
    StashSkills;
    ResetSkills;
  end;
end;

procedure THeroFrame.cbExperienceChange(Sender: TObject);
begin
  CustomiseChange(Sender);
end;

procedure THeroFrame.cbBiographyChange(Sender: TObject);
begin
  CustomiseChange(Sender);
  UpdateText(edBiography, cbBiography, FCustomBiography,GetDefaultBiography());
end;

procedure THeroFrame.cbNameChange(Sender: TObject);
begin
  CustomiseChange(Sender);
  UpdateText(edName, cbName, FCustomName,GetDefaultName);
end;

procedure THeroFrame.UpdateControls;
begin
  inherited UpdateControls;
  edPortrait.Enabled:=cbPortrait.Checked;
  edExperience.Enabled:=cbExperience.Checked;
  edName.Enabled:=cbName.Checked;
  edSex.Enabled:=cbSex.Checked;
  edBiography.Enabled:=cbBiography.Checked;
  pnSkills.Enabled := cbSkills.Checked;
end;

procedure THeroFrame.StashSkills;
begin
  FCustomSkills.Attack := Attack.Value;
  FCustomSkills.Defence := Defence.Value;
  FCustomSkills.Spellpower := SpellPower.Value;
  FCustomSkills.Knowledge := Knowledge.Value;
end;

procedure THeroFrame.LoadSkills;
begin
  Attack.Value     := FCustomSkills.Attack;
  Defence.Value    := FCustomSkills.Defence;
  SpellPower.Value := FCustomSkills.Spellpower;
  Knowledge.Value  := FCustomSkills.Knowledge;
end;

procedure THeroFrame.ResetSkills;
begin
  Attack.Value     := FDefaultSkills.Attack;
  Defence.Value    := FDefaultSkills.Defence;
  SpellPower.Value := FDefaultSkills.Spellpower;
  Knowledge.Value  := FDefaultSkills.Knowledge;
end;

procedure THeroFrame.VisitNormalHero(AOptions: THeroOptions);
begin
  inherited VisitNormalHero(AOptions);
  edHeroClass.Enabled:=False;
end;

procedure THeroFrame.VisitRandomHero(AOptions: THeroOptions);
begin
  inherited VisitRandomHero(AOptions);

  lbHeroClass.Visible:=False;
  edHeroClass.Visible:=False;
  Placeholder1.Visible:=False;

  lbType.Visible:=False;
  edType.Visible:=False;
  Placeholder2.Visible:=False;
end;

procedure THeroFrame.VisitPrison(AOptions: THeroOptions);
begin
  inherited VisitPrison(AOptions);

  lbOwner.Visible:=False;
  edOwner.Visible := False;
  Placeholder3.Visible:=False;
end;

procedure THeroFrame.UpdateText(AControl: TCustomEdit; AFlag: TCustomCheckBox;
  ACustom: TLocalizedString; ADefault: TLocalizedString);
begin
  CustomiseChange(AFlag);
  DoUpdateText(AControl, AFlag, ACustom, ADefault);
end;

constructor THeroFrame.Create(TheOwner: TComponent);
var
  p: TPlayer;
begin
  inherited Create(TheOwner);

  edOwner.Items.Clear;
  for p in TPlayerColor do
  begin
    edOwner.Items.Add(ListsManager.PlayerName[p]);
  end;
  FCustomSkills := THeroPrimarySkills.Create;
  FDefaultSkills := THeroPrimarySkills.Create;
  FClassSkills := THeroPrimarySkills.Create;
  FMapSkills := THeroPrimarySkills.Create;
end;

destructor THeroFrame.Destroy;
begin
  FMapSkills.Free;
  FClassSkills.Free;
  FCustomSkills.Free;
  FDefaultSkills.Free;
  inherited Destroy;
end;

procedure THeroFrame.Commit;
begin
  inherited Commit;

  Save();

  if Assigned(FHeroOptions) then
  begin
    CommitHeroOptions;
  end
  else
  begin
    Assert(Assigned(FHeroDefinition));

    CommitHeroDefinition;
  end;
end;

procedure THeroFrame.VisitHero(AOptions: THeroOptions);
begin
  FOptions := AOptions;
  FHeroOptions := AOptions;

  AvailableForPlaceholder.Visible:=false;
  AvailableFor.Visible := false;
  AvailableForLabel.Visible:=False;

  inherited VisitHero(AOptions);

  Load;
end;

procedure THeroFrame.VisitHeroDefinition(AOptions: THeroDefinition);
var
  h_info: THeroInfo;
  c_info: THeroClassInfo;
begin
  FOptions := AOptions;
  FHeroDefinition := AOptions;

  lbOwner.Visible:=false;
  edOwner.Visible:=false;
  Placeholder3.Visible:=false;

  lbPatrol.Visible:=false;
  edPatrol.Visible:=false;
  Placeholder5.Visible:=false;

  edHeroClass.Enabled := false;
  edType.Enabled:=false;

  h_info := ListsManager.Heroes[AOptions.Identifier];
  c_info := ListsManager.HeroClasses[h_info.&Class];

  FHeroTypeDefaults := h_info;
  FHeroMapDefaults := nil;

  FClassSkills.Assign(c_info.PrimarySkills);
  FDefaultSkills.Assign(FClassSkills);
  FMapSkills.Clear;

  edHeroClass.FillFromList(ListsManager.HeroClassInfos, h_info.&Class);
  edType.FillFromList(ListsManager.HeroInfos, h_info.Identifier);

  Load();

  inherited VisitHeroDefinition(AOptions);

  LoadAvilableFor;

  //UpdateControls();
end;


end.


