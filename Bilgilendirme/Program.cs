using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Data.SqlClient;
using Dapper;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// 1. GİZLİ BİLGİLERİ CONFIGURATION'DAN (appsettings.json) OKUYORUZ
var secretKey = builder.Configuration["JwtSettings:SecretKey"];
var connStr = builder.Configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrEmpty(secretKey) || string.IsNullOrEmpty(connStr))
{
    throw new Exception("Kritik ayarlar (SecretKey veya ConnectionString) eksik! Lütfen appsettings.json dosyasını kontrol edin.");
}

// CORS Servisini Ekliyoruz
builder.Services.AddCors();

// JWT Ayarları
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
            ValidateIssuer = false,
            ValidateAudience = false
        };
    });

builder.Services.AddAuthorizationBuilder()
    .AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));

var app = builder.Build();

// CORS Politikasını Uyguluyoruz
app.UseCors(x => x.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());

app.UseDefaultFiles(); // index.html gibi dosyaları otomatik bulur
app.UseStaticFiles();  // wwwroot klasörünü web'e açar


// 1. Yeni Personel Ekleme (Şifre Hash'leme) Endpoint'i
app.MapPost("/register", async (LoginRequest req) => {
    // Şifreyi BCrypt ile güvenli ve geri döndürülemez şekilde hashle
    string hashedPassword = BCrypt.Net.BCrypt.HashPassword(req.Password);

    using var db = new SqlConnection(connStr);
    var sql = "INSERT INTO Users (Username, Password) VALUES (@Username, @Password)";

    // Veritabanına kullanıcının girdiği düz şifreyi değil, hashedPassword'i kaydediyoruz
    await db.ExecuteAsync(sql, new { req.Username, Password = hashedPassword });

    return Results.Ok("Personel güvenli şifre ile eklendi.");
});

// 2. Güvenli Login Endpoint'i (Hash Doğrulama)
app.MapPost("/login", async (LoginRequest req) => {
    using var db = new SqlConnection(connStr);

    // Sadece kullanıcı adıyla veritabanından kullanıcıyı çek
    var sql = "SELECT * FROM Users WHERE Username = @Username";
    var user = await db.QueryFirstOrDefaultAsync<User>(sql, new { req.Username });

    if (user == null) return Results.Unauthorized();

    // Gelen düz şifreyi, veritabanındaki Hash ile karşılaştır
    bool isPasswordValid = BCrypt.Net.BCrypt.Verify(req.Password, user.Password);

    if (!isPasswordValid) return Results.Unauthorized();

    // Şifre doğruysa JWT Oluştur
    var tokenHandler = new JwtSecurityTokenHandler();
    var descriptor = new SecurityTokenDescriptor
    {
        Subject = new ClaimsIdentity(new[] {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Role, user.Role ?? "Personel")
        }),
        Expires = DateTime.UtcNow.AddDays(7),
        SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)), SecurityAlgorithms.HmacSha256Signature)
    };
    var token = tokenHandler.CreateToken(descriptor);

    return Results.Ok(new { Token = tokenHandler.WriteToken(token) });
});

// 3. İzinleri Listeleme Endpoint'i
app.MapGet("/leaves", async (HttpContext ctx) => {
    var userId = ctx.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    using var db = new SqlConnection(connStr);
    var leaves = await db.QueryAsync("SELECT * FROM Leaves WHERE UserId = @UserId", new { UserId = userId });
    return Results.Ok(leaves);
}).RequireAuthorization();

app.MapGet("/servisler", async () => {
    using var db = new SqlConnection(connStr);
    var sql = "SELECT * FROM Servisler";
    var servisler = await db.QueryAsync<Servis>(sql);
    return Results.Ok(servisler);
});

app.MapGet("/bordro", async (HttpContext ctx) => {
    var userId = ctx.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    using var db = new SqlConnection(connStr);

    var sql = "SELECT TOP 1 * FROM PersonelBordro WHERE UserId = @UserId ORDER BY Donem DESC";
    var bordro = await db.QueryFirstOrDefaultAsync<BordroModel>(sql, new { UserId = userId });

    if (bordro == null) return Results.NotFound("Bordro kaydı bulunamadı.");
    return Results.Ok(bordro);
}).RequireAuthorization();

// Sadece "AdminOnly" kuralına uyanlar (Yani token'ında Role=Admin olanlar) buraya girebilir
app.MapGet("/admin/personeller", async () => {
    using var db = new SqlConnection(connStr);
    var sql = "SELECT UserId, Username, Ad, Soyad, Bolum, Role FROM Users";
    var users = await db.QueryAsync(sql);
    return Results.Ok(users);
}).RequireAuthorization("AdminOnly");

// Sadece Adminlerin erişebileceği detaylı personel ekleme servisi
app.MapPost("/admin/personel-ekle", async (AdminKullaniciEkleRequest req) => {
    string hashedPassword = BCrypt.Net.BCrypt.HashPassword(req.Password);

    using var db = new SqlConnection(connStr);
    var sql = @"INSERT INTO Users 
                (Username, Password, TcNo, Bolum, Unvan, IseGiris, Ad, Soyad, Role) 
                VALUES 
                (@Username, @Password, @TcNo, @Bolum, @Unvan, @IseGiris, @Ad, @Soyad, @Role)";

    await db.ExecuteAsync(sql, new
    {
        req.Username,
        Password = hashedPassword,
        req.TcNo,
        req.Bolum,
        req.Unvan,
        req.IseGiris,
        req.Ad,
        req.Soyad,
        req.Role
    });

    return Results.Ok();
}).RequireAuthorization("AdminOnly");

// Admin: Personel Bilgilerini Güncelleme Endpoint'i
app.MapPut("/admin/personel-guncelle", async (PersonelGuncelleRequest req) => {
    using var db = new SqlConnection(connStr);
    var sql = @"UPDATE Users 
                SET Ad = @Ad, Soyad = @Soyad, TcNo = @TcNo, Bolum = @Bolum, Role = @Role 
                WHERE UserId = @UserId";
    await db.ExecuteAsync(sql, req);
    return Results.Ok();
}).RequireAuthorization("AdminOnly");

// Admin: Personele Yeni Bordro (Maaş) Ekleme Endpoint'i
app.MapPost("/admin/bordro-ekle", async (BordroEkleRequest req) => {
    using var db = new SqlConnection(connStr);
    var sql = @"INSERT INTO PersonelBordro 
                (UserId, Donem, NetMaas, KalanIzin, BrutMaas, MesaiEkOdeme, YemekYolYardimi, Kesintiler) 
                VALUES 
                (@UserId, @Donem, @NetMaas, @KalanIzin, @BrutMaas, @MesaiEkOdeme, @YemekYolYardimi, @Kesintiler)";
    await db.ExecuteAsync(sql, req);
    return Results.Ok();
}).RequireAuthorization("AdminOnly");

app.UseAuthentication();
app.UseAuthorization();

app.Run();

// ---------------- DTO ve Modeller ----------------

public record LoginRequest(
    string Username,
    string Password
);

public record User(
    int UserId,
    string Username,
    string Password,
    string TcNo,
    string Bolum,
    string Unvan,
    DateTime IseGiris,
    string Ad,
    string Soyad,
    string Role
);

public record BordroModel(
    int UserId,
    string Donem,
    decimal NetMaas,
    int KalanIzin,
    decimal BrutMaas,
    decimal MesaiEkOdeme,
    decimal YemekYolYardimi,
    decimal Kesintiler
);

public record Servis(
    int Id,
    string Ilce,
    string Bolge,
    string Plaka,
    string Telefon,
    string ServisNo
);

public record AdminKullaniciEkleRequest(
    string Username,
    string Password,
    string TcNo,
    string Bolum,
    string Unvan,
    DateTime IseGiris,
    string Ad,
    string Soyad,
    string Role
);

public record PersonelGuncelleRequest(
    int UserId, string Ad, string Soyad, string TcNo, string Bolum, string Role
);

public record BordroEkleRequest(
    int UserId, string Donem, decimal NetMaas, int KalanIzin,
    decimal BrutMaas, decimal MesaiEkOdeme, decimal YemekYolYardimi, decimal Kesintiler
);