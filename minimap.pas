{ This file is a part of Map editor for VCMI project

  Copyright (C) 2013-2016 Alexander Shishkin alexvins@users.sourceforge.net

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
unit minimap;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, math, fgl, Graphics, Map, editor_types, editor_utils, editor_consts, editor_classes, ExtCtrls,
  LCLProc, IntfGraphics;

type

  TBitmaps = specialize TFPGObjectList<TBitmap>;

  { TMinimap }

  TMinimap = class (TComponent)
  private
    FTerrainColors: array[TTerrainType] of TColor;
    FTerrainBlockColors: array[TTerrainType] of TColor;
    FMap: TVCMIMap;

    FMapImg : TBitmap;

    FMapImgs: TBitmaps;

    FMapImgValid: Boolean;

    FScale: Double;

    procedure MayBeUpdateImg;

    procedure SetMap(AValue: TVCMIMap);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Map: TVCMIMap read FMap write SetMap;

    procedure Paint(pb: TPaintBox; ARadarRect: TRect);

    procedure InvalidateLevel; //todo:InvalidateLevel

    procedure InvalidateMap;
  end;

implementation


{ TMinimap }

constructor TMinimap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FterrainColors[TTerrainType.dirt] := RGBToColor( 82, 56, 8 );
  FterrainColors[TTerrainType.sand] := RGBToColor(222, 207, 140);
  FterrainColors[TTerrainType.grass] := RGBToColor(0, 65, 0 );
  FterrainColors[TTerrainType.snow] := RGBToColor(181, 199, 198);
  FTerrainColors[TTerrainType.swamp] := RGBToColor(74, 134, 107);

  FterrainColors[TTerrainType.rough] := RGBToColor(132, 113, 49);
  FterrainColors[TTerrainType.subterra] := RGBToColor(132, 48, 0);
  FterrainColors[TTerrainType.lava] := RGBToColor(74, 73, 74);
  FterrainColors[TTerrainType.water] := RGBToColor (8, 81, 148);
  FterrainColors[TTerrainType.rock] := RGBToColor(0, 0, 0);

  FTerrainBlockColors[TTerrainType.dirt] := RGBToColor( 57, 40, 8 );
  FTerrainBlockColors[TTerrainType.sand] := RGBToColor(165, 158, 107);
  FTerrainBlockColors[TTerrainType.grass] := RGBToColor(0, 48, 0 );
  FTerrainBlockColors[TTerrainType.snow] := RGBToColor(140, 158, 156);
  FTerrainBlockColors[TTerrainType.swamp] := RGBToColor(33, 89, 66);

  FTerrainBlockColors[TTerrainType.rough] := RGBToColor(99, 81, 33);
  FTerrainBlockColors[TTerrainType.subterra] := RGBToColor(90, 8, 0);
  FTerrainBlockColors[TTerrainType.lava] := RGBToColor(41, 40, 41);
  FTerrainBlockColors[TTerrainType.water] := RGBToColor (8, 81, 148);
  FTerrainBlockColors[TTerrainType.rock] := RGBToColor(0, 0, 0);

  FMapImg := TBitmap.Create;

  FMapImgs := TBitmaps.Create(True);
end;

destructor TMinimap.Destroy;
begin
  FMapImgs.Free;

  FMapImg.Free;
  inherited Destroy;
end;

procedure TMinimap.InvalidateLevel;
begin
  //todo
end;

procedure TMinimap.InvalidateMap;
begin
  FMapImgValid := False;
end;

procedure TMinimap.MayBeUpdateImg;
var
  level: Integer;

  row, col, x, y: Integer;
  tile_size: Integer;

  tile: PMapTile;

  TempImage: TLazIntfImage;
  left, top, right, bottom, imgWidth, imgHeight, levelWidth, levelHeight: Integer;
  id: Int32;
  c: TPlayer;
begin
  if not Assigned(FMap) then
    Exit;
  if FMapImgValid then
    Exit;
  level := FMap.CurrentLevelIndex;

  TempImage := FMapImg.CreateIntfImage;

  try
    imgWidth :=  FMapImg.Width;
    imgHeight :=  FMapImg.Height;

    levelWidth := Fmap.CurrentLevel.Width;
    levelHeight := FMap.CurrentLevel.Height;

    FScale := imgWidth / levelWidth;

    tile_size := trunc(FScale)+1;

    for row := 0 to levelHeight - 1 do
    begin
      for col := 0 to levelWidth - 1 do
      begin
        tile := FMap.GetTile(level,col,row);

        left := trunc(col*FScale);
        top := trunc(row*FScale);

        right := Min(left + tile_size, imgWidth-1);
        bottom := Min(top + tile_size, imgHeight-1);

        for x := left to right do
        begin
          for y := top to bottom do
          begin
            id := tile^.FlaggableID;

            if id >= 0 then
            begin
              c := tile^.Owner;

              if c = TPlayer.none then
              begin
                TempImage.Colors[x,y] := RGBAColorToFpColor (NEWTRAL_PLAYER_COLOR);
              end
              else
              begin
                TempImage.Colors[x,y] := RGBAColorToFpColor (PLAYER_FLAG_COLORS[TPlayerColor(c)]);
              end;
            end
            else if tile^.IsBlocked then
            begin
              TempImage.Colors[x,y] := TColorToFPColor(FTerrainBlockColors[tile^.TerType]);
            end
            else
            begin
              TempImage.Colors[x,y] := TColorToFPColor(FterrainColors[tile^.TerType]);
            end;
          end;
        end;
      end;
    end;
    FMapImg.LoadFromIntfImage(TempImage);
  finally
    TempImage.Free;
  end;

  FMapImgValid := True;
end;

procedure TMinimap.Paint(pb: TPaintBox; ARadarRect: TRect);
var
  scaled_radar:  TRect;
begin
  if not Assigned(FMap) then
    Exit;
  //TODO: more accurate painting
  //todo: invalidate map only on change

  if (FMapImg.Width<>pb.Width) or (FMapImg.Height<>pb.Height) then
  begin
    FMapImg.SetSize(pb.Width,pb.Height);
    InvalidateMap;
  end;

  MayBeUpdateImg;

  try
    pb.Canvas.Changing;
    pb.Canvas.Draw(0,0,FMapImg);
    pb.Canvas.Pen.Style := psDot;
    pb.Canvas.Pen.Color := clGray;

    scaled_radar := ARadarRect;
    scaled_radar.Right:=round(FScale*scaled_radar.Right);
    scaled_radar.Left:=round(FScale*scaled_radar.Left);
    scaled_radar.Top:=round(FScale*scaled_radar.Top);
    scaled_radar.Bottom:=round(FScale*scaled_radar.Bottom);

    pb.Canvas.Frame(scaled_radar);
  finally
    pb.Canvas.Changed;
  end;

end;

procedure TMinimap.SetMap(AValue: TVCMIMap);
var
  i: Integer;
  level_bitmap: TBitmap;
begin
  FMap := AValue;

  FMapImgs.Clear;

  for i := 0 to FMap.MapLevels.Count - 1 do
  begin
    level_bitmap := TBitmap.Create;

    FMapImgs.Add(level_bitmap);
  end;

  FMapImgValid := False;
end;

end.

