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

unit editor_gl;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, math, matrix, GL, glext40;

type
  TRBGAColor = packed record
    r,g,b,a : UInt8;
  end;

const
  //SHADER_VERSION =  '#version 130'#13#10;
  SHADER_VERSION =  '#version 330 core'#13#10;

  VERTEX_DEFAULT_SHADER =
  SHADER_VERSION+
  'uniform mat4 projMatrix;'#13#10+
  'uniform mat4 translateMatrix;'#13#10+

  'in vec2 coords;'#13#10+
  'in vec2 uv;'#13#10+

  'out vec2 UV;'#13#10+
  'void main(){'+
    'UV = uv;'+
  	'gl_Position = projMatrix * translateMatrix * vec4(coords,0.0,1.0);'#13#10+
  '}';

  FRAGMENT_DEFAULT_SHADER =
  SHADER_VERSION+
  'const vec4 eps = vec4(0.009, 0.009, 0.009, 0.009);'+
  'const vec4 maskColor = vec4(1.0, 1.0, 0.0, 0.0);'+
  'uniform usampler2D bitmap;'+
  'uniform sampler1D palette;'+
  'uniform int useTexture = 0;'+
  'uniform int usePalette = 0;'+
  'uniform int useFlag = 0;'+
  'uniform vec4 flagColor;'+
  'uniform vec4 fragmentColor;'#13#10+
  'in vec2 UV;'#13#10+
  'out vec4 outColor;'#13#10+

  'vec4 applyTexture(vec4 inColor)'+
  '{'+
      'if(useTexture == 1)'+
      '{'+
         'if(usePalette == 1)'+
          '{'+
              'return texelFetch(palette, int(texture(bitmap,UV).r), 0);'+
          '}'+
          'else'+
          '{' +
             // 'return texture(bitmap,UV);'+ //???
          '}'+
      '}'+
       'return inColor;'+
  '}'+

  'vec4 applyFlag(vec4 inColor)' +
  '{'+
     'if(useFlag == 1)'+
     '{'+
        'if(all(greaterThanEqual(inColor,maskColor-eps)) && all(lessThanEqual(inColor,maskColor+eps)))'+
        '  return flagColor;'+
     '}'+
     'return inColor;'+
  '}'+

  'void main(){'+
      'outColor = applyTexture(fragmentColor);'+
      'outColor = applyFlag(outColor);'+
  '}';

  //VERTEX_TERRAIN_SHADER =
  //  SHADER_VERSION+
  //  'uniform mat4 projMatrix;'#13#10+
  //  'layout(location = 1) in vec2 coords;'#13#10+
  //  'struct Tile{'+
  //  '  uint upper;'+ //packed data     FTerType, FTerSubtype, FRiverType, FRiverDir
  //  '  uint lower;'+ //packed data     FRoadType, FRoadDir,  FFlags, FOwner
  //  '};'+
  //  'layout(location = 2) in Tile tileIn'+
  //  'out Tile tileOut'+
  //  'void main(){'+
  //    'tileOut = tileIn;'+
  //    'gl_Position = projMatrix * vec4(coords,0.0,1.0);'#13#10+
  //  '}';


  //GEOMETRY_TERRAIN_SHADER =
  //  SHADER_VERSION+
  //  '';


type

  TGLSprite = record
    TextureID: GLuint;
    PaletteID: Gluint;
    Width: Int32;
    Height: Int32;

    TopMargin: int32;
    LeftMargin: int32;

    SpriteWidth: Int32;
    SpriteHeight: int32;
  end;

  { TGlobalState }

  TGlobalState = class
  private
    const
       VERTEX_BUFFER_SIZE = 4 * 2 * 3 * 2; //4 rotation * 2 triangles * 3 poitns * 2 coordinates
       UV_BUFFER_SIZE = VERTEX_BUFFER_SIZE; //also 2 coordinates
  private

    FCoordAttribLocation: GLint;
    FUVAttribLocation: GLint;

    EmptyBufferData:array of GLfloat; //todo: use to initialize VBO
  private

    DefaultProgram: GLuint;
    DefaultFragmentColorUniform: GLint;
    DefaultProjMatrixUniform: GLint;
    DefaultTranslateMatrixUniform: GLint;
    UseTextureUniform: GLint;
    UsePaletteUniform: GLint;
    UseFlagUniform: GLint;
    PaletteUniform: GLint;
    BitmapUniform: GLint;
    FlagColorUniform: GLint;

    CoordsBuffer: GLuint;
    MirroredUVBuffer: GLuint;

    procedure SetupUVBuffer;
    procedure SetupCoordsBuffer;

  public
    constructor Create;
    destructor Destroy; override;
    procedure Init;
  end;


  { TLocalState }

  TLocalState = class
  private
    SpriteVAO: GLuint;
    RectVAO: GLuint;

    FCurrentProgram: GLuint;

    FTranslateMaxrix: Tmatrix4_single;

    procedure SetupSpriteVAO;
    procedure SetupRectVAO;

    procedure SetProjection(constref AMatrix: Tmatrix4_single);

    procedure DoRenderSprite(ASprite: TGLSprite; x,y,w,h: Int32; mir: UInt8);
 public
    procedure SetFlagColor(FlagColor: TRBGAColor);
    procedure SetFragmentColor(AColor: TRBGAColor);
    procedure SetOrtho(left, right, bottom, top: GLfloat);

    procedure SetTranslation(X,Y: Integer);
    procedure ApplyTranslation;

    procedure SetUseFlag(const Value: Boolean);
    procedure SetUsePalette(const Value: Boolean);
    procedure SetUseTexture(const Value: Boolean);
    procedure UseNoTextures;
    procedure UsePalettedTextures;

    constructor Create;
    destructor Destroy; override;

    procedure Init;

    procedure StartDrawingRects;
    procedure RenderRect(x, y: Integer; dimx, dimy: integer; color: TRBGAColor);

    procedure RenderSolidRect(x, y: Integer; dimx, dimy: integer; color: TRBGAColor);

    procedure StartDrawingSprites;

    procedure RenderSpriteMirrored(ASprite: TGLSprite; mir: UInt8);

    procedure RenderSpriteSimple(ASprite: TGLSprite);
    procedure RenderSpriteIcon(ASprite: TGLSprite; dim: Integer);

    procedure StopDrawing;

  end;



procedure BindPalette(ATextureId: GLuint; ARawImage: Pointer);

procedure BindUncompressedPaletted(ATextureId: GLuint; w,h: Int32; ARawImage: Pointer);

procedure BindUncompressedRGBA(ATextureId: GLuint; w,h: Int32; var ARawImage);
procedure BindCompressedRGBA(ATextureId: GLuint; w,h: Int32; var ARawImage);
procedure Unbind(var ATextureId: GLuint); inline;

procedure CheckGLErrors(Stage: string);

function MakeShaderProgram(const AVertexSource: AnsiString; const AFragmentSource: AnsiString):GLuint;

var
  GlobalContextState: TGlobalState;
  CurrentContextState:TLocalState = nil;

implementation

uses LazLoggerBase;


procedure BindRGBA(ATextureId: GLuint; w, h: Int32; ARawImage: Pointer; AInternalFormat: GLEnum); inline;
begin

  glBindTexture(GL_TEXTURE_2D, ATextureId);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  glTexImage2D(GL_TEXTURE_2D, 0,AInternalFormat,w,h,0,GL_RGBA, GL_UNSIGNED_BYTE, ARawImage);

end;

procedure BindPalette(ATextureId: GLuint; ARawImage: Pointer);
begin
  glBindTexture(GL_TEXTURE_1D, ATextureId);

  glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  glTexImage1D(GL_TEXTURE_1D, 0,GL_RGBA,256,0,GL_RGBA, GL_UNSIGNED_BYTE, ARawImage);


  CheckGLErrors('Bind palette');
end;


procedure BindUncompressedPaletted(ATextureId: GLuint; w, h: Int32;
  ARawImage: Pointer);
begin
  glBindTexture(GL_TEXTURE_2D, ATextureId);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

  glTexImage2D(GL_TEXTURE_2D, 0,GL_R8UI,w,h,0,GL_RED_INTEGER, GL_UNSIGNED_BYTE, ARawImage);

   CheckGLErrors('Bind paletted');
end;

procedure BindUncompressedRGBA(ATextureId: GLuint; w, h: Int32; var ARawImage);
begin
  BindRGBA(ATextureId,w, h,@ARawImage,GL_RGBA);
end;

procedure BindCompressedRGBA(ATextureId: GLuint; w, h: Int32; var ARawImage);
begin
  BindRGBA(ATextureId,w, h,@ARawImage,GL_COMPRESSED_RGBA);
end;

procedure Unbind(var ATextureId: GLuint);
begin
  glDeleteTextures(1,@ATextureId);
  ATextureId := 0;
end;

procedure CheckGLErrors(Stage: string);
var
  err: GLenum;
begin

  repeat
    err := glGetError();

    if err<>GL_NO_ERROR then
    begin
      DebugLogger.DebugLn(Stage +': Gl error '+IntToHex(err,8));
    end;

  until err = GL_NO_ERROR ;


end;

function MakeShader(const ShaderSource: AnsiString; ShaderType: GLenum): GLuint;
var
  shader_object: GLuint;
  status: Integer;
  info_log_len: GLint;

  info_log: string;
begin
  Result := 0;
  shader_object := glCreateShader(ShaderType);

  if shader_object = 0 then
  begin
    CheckGLErrors('MakeShader');
    Exit;
  end;

  glShaderSource(shader_object,1,@(ShaderSource),nil);
  glCompileShader(shader_object);
  status := GL_FALSE;
  glGetShaderiv(shader_object,GL_COMPILE_STATUS,@status);

  if status <> GL_TRUE then
  begin
    glGetShaderiv(shader_object,GL_INFO_LOG_LENGTH, @info_log_len);
    SetLength(info_log,info_log_len);
    glGetShaderInfoLog(shader_object,info_log_len,@info_log_len,@info_log[1]);

    DebugLn('Shader compile log:');
    DebugLn(info_log);
    exit;
  end;

  Result := shader_object;

end;

function MakeShaderProgram(const AVertexSource: AnsiString;
  const AFragmentSource: AnsiString): GLuint;
var
  vertex_shader, fragment_shader: GLuint;
  status: GLint;
  program_object: GLuint;
  doVertex: Boolean;
  doFragment: Boolean;
begin
  Result := 0;
  vertex_shader := 0;
  fragment_shader := 0;

  doVertex := AVertexSource <> '';
  doFragment := AFragmentSource <> '';

  program_object := glCreateProgram();

  if doVertex then
  begin
    vertex_shader := MakeShader(AVertexSource, GL_VERTEX_SHADER);
    if vertex_shader = 0 then Exit;
    glAttachShader(program_object, vertex_shader);
  end;

  if doFragment then
  begin
    fragment_shader := MakeShader(AFragmentSource, GL_FRAGMENT_SHADER);
    if fragment_shader = 0 then Exit;
    glAttachShader(program_object, fragment_shader);
  end;

  glLinkProgram(program_object);
  status := GL_FALSE;
  glGetProgramiv(program_object, GL_LINK_STATUS, @status);

  if (status = GL_TRUE) then
    Result := program_object;


  if doVertex then glDeleteShader(vertex_shader); //always mark shader for deletion
  if doFragment then glDeleteShader(fragment_shader);
end;

{ TGlobalState }

procedure TGlobalState.SetupUVBuffer;
var
  uv_data: packed array of GLfloat;
  u: GLfloat;
  v: GLfloat;
  mir: Integer;

  ofc: integer;

  function next_ofc(): integer;
  begin
    Result := ofc;
    inc(ofc);
  end;
begin
  SetLength(uv_data, UV_BUFFER_SIZE);

  u:=1;
  v:=1;

  for mir := 0 to 3 do
  begin
    ofc := mir * 12;

    case mir of
      0:begin
          uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := 0;
          uv_data[next_ofc()] := u;   uv_data[next_ofc()] := 0;
          uv_data[next_ofc()] := u;   uv_data[next_ofc()] := v;

          uv_data[next_ofc()] := u;   uv_data[next_ofc()] := v;
          uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := v;
          uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := 0;
      end;
      1: begin
            uv_data[next_ofc()] := u;   uv_data[next_ofc()] := 0;
            uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := 0;
            uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := v;

            uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := v;
            uv_data[next_ofc()] := u;   uv_data[next_ofc()] := v;
            uv_data[next_ofc()] := u;   uv_data[next_ofc()] := 0;
        end;
      2: begin
            uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := v;
            uv_data[next_ofc()] := u;   uv_data[next_ofc()] := v;
            uv_data[next_ofc()] := u;   uv_data[next_ofc()] := 0;

            uv_data[next_ofc()] := u;   uv_data[next_ofc()] := 0;
            uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := 0;
            uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := v;
        end;
      3:begin
          uv_data[next_ofc()] := u;   uv_data[next_ofc()] := v;
          uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := v;
          uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := 0;

          uv_data[next_ofc()] := 0;   uv_data[next_ofc()] := 0;
          uv_data[next_ofc()] := u;   uv_data[next_ofc()] := 0;
          uv_data[next_ofc()] := u;   uv_data[next_ofc()] := v;
        end;
     end;

  end;

  glGenBuffers(1, @MirroredUVBuffer);
  glBindBuffer(GL_ARRAY_BUFFER,MirroredUVBuffer);
  glBufferData(GL_ARRAY_BUFFER,UV_BUFFER_SIZE * SizeOf(GLfloat),@uv_data[0],GL_STATIC_DRAW);
end;

procedure TGlobalState.SetupCoordsBuffer;
begin
  glGenBuffers(1,@CoordsBuffer);
  glBindBuffer(GL_ARRAY_BUFFER,GlobalContextState.CoordsBuffer);
  glBufferData(GL_ARRAY_BUFFER, VERTEX_BUFFER_SIZE * SizeOf(GLfloat), @EmptyBufferData[0], GL_STREAM_DRAW);
end;

constructor TGlobalState.Create;
begin
  SetLength(EmptyBufferData, VERTEX_BUFFER_SIZE); //do not care even if it will contain junk
end;

destructor TGlobalState.Destroy;
begin
  glDeleteProgram(DefaultProgram);

  inherited Destroy;
end;

procedure TGlobalState.Init;
begin
  DefaultProgram := MakeShaderProgram(VERTEX_DEFAULT_SHADER, FRAGMENT_DEFAULT_SHADER);
  if DefaultProgram = 0 then
    raise Exception.Create('Error compiling default shader');

  DefaultFragmentColorUniform:= glGetUniformLocation(DefaultProgram, PChar('fragmentColor'));

  DefaultProjMatrixUniform := glGetUniformLocation(DefaultProgram, PChar('projMatrix'));
  DefaultTranslateMatrixUniform := glGetUniformLocation(DefaultProgram, PChar('translateMatrix'));

  UseFlagUniform:=glGetUniformLocation(DefaultProgram, PChar('useFlag'));
  UsePaletteUniform:=glGetUniformLocation(DefaultProgram, PChar('usePalette'));
  UseTextureUniform:=glGetUniformLocation(DefaultProgram, PChar('useTexture'));

  PaletteUniform:=glGetUniformLocation(DefaultProgram, PChar('palette'));
  FlagColorUniform:=glGetUniformLocation(DefaultProgram, PChar('flagColor'));
  BitmapUniform:=glGetUniformLocation(DefaultProgram, PChar('bitmap'));

  FCoordAttribLocation:=glGetAttribLocation(DefaultProgram, PChar('coords'));
  FUVAttribLocation:=glGetAttribLocation(DefaultProgram, PChar('uv'));

  CheckGLErrors('default shader get uniforms');

  SetupCoordsBuffer;
  SetupUVBuffer;
  CheckGLErrors('VBO');
end;


{ TLocalState }

constructor TLocalState.Create;
begin
  FTranslateMaxrix.init_identity;
end;

destructor TLocalState.Destroy;
begin
  inherited Destroy;
end;

procedure TLocalState.Init;
begin
  SetupSpriteVAO;
  SetupRectVAO;
  CheckGLErrors('VAO');
end;

procedure TLocalState.RenderRect(x, y: Integer; dimx, dimy: integer;
  color: TRBGAColor);
var
  vertex_data: packed array[1..8] of GLfloat;
begin
  SetTranslation(x,y);

  SetFragmentColor(color);
//  glLineWidth(1);

  vertex_data[1] := 0;
  vertex_data[2] := 0;
  vertex_data[3] := 0 + dimx;
  vertex_data[4] := 0;
  vertex_data[5] := 0 + dimx;
  vertex_data[6] := 0 + dimy;
  vertex_data[7] := 0;
  vertex_data[8] := 0 + dimy;

  ApplyTranslation;

  glBindBuffer(GL_ARRAY_BUFFER,GlobalContextState.CoordsBuffer);
  glBufferSubData(GL_ARRAY_BUFFER,0, sizeof(vertex_data),@vertex_data);
  glBindBuffer(GL_ARRAY_BUFFER, 0);

  glDrawArrays(GL_LINE_LOOP,0,4);

end;

procedure TLocalState.RenderSolidRect(x, y: Integer; dimx, dimy: integer;
  color: TRBGAColor);
var
  vertex_data: packed array[1..12] of GLfloat;
begin
  SetFragmentColor(color);

  ApplyTranslation;

  vertex_data[1] := x;   vertex_data[2] := y;
  vertex_data[3] := x+dimx; vertex_data[4] := y;
  vertex_data[5] := x+dimx; vertex_data[6] := y+dimy;

  vertex_data[7] := x+dimx; vertex_data[8] := y+dimy;
  vertex_data[9] := x;   vertex_data[10] := y+dimy;
  vertex_data[11] := x;  vertex_data[12] := y;

  glBindBuffer(GL_ARRAY_BUFFER,GlobalContextState.CoordsBuffer);
  glBufferSubData(GL_ARRAY_BUFFER, sizeof(vertex_data),  sizeof(vertex_data),@vertex_data);
  glBindBuffer(GL_ARRAY_BUFFER,0);

  ApplyTranslation;

  glDrawArrays(GL_TRIANGLES,6,6);  //todo: use triangle strip
end;

procedure TLocalState.StopDrawing;
begin
  glBindVertexArray(0);
  glDisableVertexAttribArray(GlobalContextState.FCoordAttribLocation);
  glDisableVertexAttribArray(GlobalContextState.FUVAttribLocation);
  SetTranslation(0,0);
end;

procedure TLocalState.StartDrawingRects;
begin
  SetTranslation(0,0);
  glBindVertexArray(RectVAO);
  glEnableVertexAttribArray(GlobalContextState.FCoordAttribLocation);
  glDisableVertexAttribArray(GlobalContextState.FUVAttribLocation);
end;

procedure TLocalState.StartDrawingSprites;
begin
  SetTranslation(0,0);
  glBindVertexArray(SpriteVAO);
  glEnableVertexAttribArray(GlobalContextState.FCoordAttribLocation);
  glEnableVertexAttribArray(GlobalContextState.FUVAttribLocation);
end;

procedure TLocalState.RenderSpriteMirrored(ASprite: TGLSprite; mir: UInt8);
var
  H,W,
  x,
  y,
  TopMargin: Int32;
begin
  H := ASprite.SpriteHeight;
  W := ASprite.Width;
  TopMargin := ASprite.TopMargin;

  //todo: use indexes

  case mir of
    0:begin
      x := 0;//+round(factor * ASprite.LeftMargin);
      y := 0 +TopMargin;
    end;
    1:begin
      x := 0;//+round(factor * (ASprite.Width - ASprite.SpriteWidth - ASprite.LeftMargin));
      y := 0+ASprite.TopMargin;

    end;
    2:begin
      x := 0;//+ round(factor * ASprite.LeftMargin);
      y := 0+(ASprite.Height - ASprite.SpriteHeight - ASprite.TopMargin);

    end;
    3:begin
      x := 0;//+round(factor * (ASprite.Width - ASprite.SpriteWidth - ASprite.LeftMargin));
      y := 0+(ASprite.Height - ASprite.SpriteHeight - ASprite.TopMargin);
     end;
  end;

  DoRenderSprite(ASprite, x,y,w,h, mir);
end;

procedure TLocalState.RenderSpriteSimple(ASprite: TGLSprite);
var
  H,W,
  x,
  y,
  TopMargin: Int32;
begin
    H := ASprite.SpriteHeight;
    W := ASprite.Width;
    TopMargin := ASprite.TopMargin;
    x := 0;//+round(factor * ASprite.LeftMargin);
    y := 0 +TopMargin;

  DoRenderSprite(ASprite, x,y,w,h, 0);
end;

procedure TLocalState.RenderSpriteIcon(ASprite: TGLSprite; dim: Integer);
var
  factor: Double;
  cur_dim: integer;
  H,W,
  x,
  y,
  TopMargin: Int32;
begin
  cur_dim := Max(ASprite.Width,ASprite.SpriteHeight);

  factor := Min((dim-1) / cur_dim, 1); //no zoom

  h := round(Double(ASprite.SpriteHeight) * factor);
  w := round(Double(ASprite.Width) * factor);

  TopMargin := dim - 1 - h;


  x := 0;//+round(factor * ASprite.LeftMargin);
  y := 0 +TopMargin;

  DoRenderSprite(ASprite, x,y,w,h, 0);
end;


procedure TLocalState.SetOrtho(left, right, bottom, top: GLfloat);
var
  M:Tmatrix4_single;
begin
  m.init_identity;
  m.data[0,0] := 2 /(right - left);
  m.data[1,1] := 2 /(top - bottom);
  m.data[2,2] := -2;

  m.data[0,3] := - (right+left)/(right-left);
  m.data[1,3] := - (top + bottom)/(top - bottom);
  m.data[2,3] := - 1;

  SetProjection(m);
end;

procedure TLocalState.SetTranslation(X, Y: Integer);
begin
  FTranslateMaxrix.init_identity;
  FTranslateMaxrix.data[0,3] := x;
  FTranslateMaxrix.data[1,3] := y;
end;

procedure TLocalState.ApplyTranslation;
begin
  glUniformMatrix4fv(GlobalContextState.DefaultTranslateMatrixUniform,1,GL_TRUE,@FTranslateMaxrix.data);
end;

procedure TLocalState.SetupSpriteVAO;
begin
  glGenVertexArrays(1,@SpriteVAO);

  glBindVertexArray(SpriteVAO);

  glBindBuffer(GL_ARRAY_BUFFER,GlobalContextState.CoordsBuffer);
  glVertexAttribPointer(GlobalContextState.FCoordAttribLocation, 2, GL_FLOAT, GL_FALSE, 0,nil);

  glBindBuffer(GL_ARRAY_BUFFER,GlobalContextState.MirroredUVBuffer);
  glVertexAttribPointer(GlobalContextState.FUVAttribLocation, 2, GL_FLOAT, GL_FALSE, 0,nil);

  glBindBuffer(GL_ARRAY_BUFFER, 0);

  glBindVertexArray(0);

end;

procedure TLocalState.SetupRectVAO;
begin
   glGenVertexArrays(1,@RectVAO);
   glBindVertexArray(RectVAO);
   glBindBuffer(GL_ARRAY_BUFFER,GlobalContextState.CoordsBuffer);
   glVertexAttribPointer(GlobalContextState.FCoordAttribLocation, 2, GL_FLOAT, GL_FALSE, 0,nil);
   glBindBuffer(GL_ARRAY_BUFFER, 0);
   glBindVertexArray(0);
end;

procedure TLocalState.SetFlagColor(FlagColor: TRBGAColor);
begin
  if FCurrentProgram = GlobalContextState.DefaultProgram then
  begin
    glUniform4f(GlobalContextState.FlagColorUniform, FlagColor.r/255, FlagColor.g/255, FlagColor.b/255, FlagColor.a/255);
  end;

end;

procedure TLocalState.SetFragmentColor(AColor: TRBGAColor);
begin
  if FCurrentProgram = GlobalContextState.DefaultProgram then
  begin
    glUniform4f(GlobalContextState.DefaultFragmentColorUniform, AColor.r/255, AColor.g/255, AColor.b/255, AColor.a/255 );
  end
  else
    Assert(false);
end;

procedure TLocalState.SetProjection(constref AMatrix: Tmatrix4_single);
begin
  if FCurrentProgram = GlobalContextState.DefaultProgram then
  begin
    glUniformMatrix4fv(GlobalContextState.DefaultProjMatrixUniform,1,GL_TRUE,@AMatrix.data);
  end
  else
    Assert(false);
end;

procedure TLocalState.DoRenderSprite(ASprite: TGLSprite; x, y, w, h: Int32;
  mir: UInt8);
var
  vertex_data: packed array[1..12] of GLfloat;
begin
  vertex_data[1] := x;   vertex_data[2] := y;
  vertex_data[3] := x+w; vertex_data[4] := y;
  vertex_data[5] := x+w; vertex_data[6] := y+h;

  vertex_data[7] := x+w; vertex_data[8] := y+h;
  vertex_data[9] := x;   vertex_data[10] := y+h;
  vertex_data[11] := x;  vertex_data[12] := y;

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D,ASprite.TextureID);

  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_1D,ASprite.PaletteID);

  glBindBuffer(GL_ARRAY_BUFFER,GlobalContextState.CoordsBuffer);
  glBufferSubData(GL_ARRAY_BUFFER, mir*sizeof(vertex_data),  sizeof(vertex_data),@vertex_data);
  glBindBuffer(GL_ARRAY_BUFFER,0);

  ApplyTranslation;

  glDrawArrays(GL_TRIANGLES,mir*6,6);  //todo: use triangle strip
end;

procedure TLocalState.SetUseFlag(const Value: Boolean);
begin
  glUniform1i(GlobalContextState.UseFlagUniform, ifthen(Value, 1, 0));
end;

procedure TLocalState.SetUsePalette(const Value: Boolean);
begin
  glUniform1i(GlobalContextState.UsePaletteUniform, ifthen(Value, 1, 0));
end;

procedure TLocalState.SetUseTexture(const Value: Boolean);
begin
  glUniform1i(GlobalContextState.UseTextureUniform, ifthen(Value, 1, 0));
end;

procedure TLocalState.UseNoTextures;
begin
  FCurrentProgram := GlobalContextState.DefaultProgram;
  glUseProgram(GlobalContextState.DefaultProgram);
  SetUseFlag(false);
  SetUsePalette(false);
  SetUseTexture(False);
end;

procedure TLocalState.UsePalettedTextures;
begin
  FCurrentProgram := GlobalContextState.DefaultProgram;
  glUseProgram(GlobalContextState.DefaultProgram);

  SetUsePalette(true);
  SetUseTexture(true);

  glUniform1i(GlobalContextState.BitmapUniform, 0); //texture unit0
  glUniform1i(GlobalContextState.PaletteUniform, 1);//texture unit1

end;



end.

