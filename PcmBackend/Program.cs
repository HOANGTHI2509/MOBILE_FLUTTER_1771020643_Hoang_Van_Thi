using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;

var builder = WebApplication.CreateBuilder(args);

// --- 1. Cấu hình Database ---
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// --- 2. Identity & Cấu hình bảo mật đơn giản ---
builder.Services.AddIdentityApiEndpoints<IdentityUser>()
    .AddEntityFrameworkStores<ApplicationDbContext>();

builder.Services.Configure<IdentityOptions>(options => {
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 4;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireLowercase = false;
});

// --- 3. Cấu hình CORS (QUAN TRỌNG ĐỂ SỬA LỖI WEB) ---
builder.Services.AddCors(options => {
    options.AddPolicy("AllowAll", policy => {
        policy.SetIsOriginAllowed(origin => true) // Allow any origin properly
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials(); // Important for some auth scenarios, though JWT usually doesn't need it if sent in header
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSignalR();
builder.Services.AddHostedService<PcmBackend.Services.AutoCancelService>();

var app = builder.Build();

// --- 4. Cấu hình Middleware Pipeline ---
// LƯU Ý: UseCors PHẢI nằm trước Authentication và MapControllers
app.UseCors("AllowAll"); 
app.UseStaticFiles(); 

if (app.Environment.IsDevelopment()) {
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapIdentityApi<IdentityUser>();
app.MapControllers();
app.MapHub<PcmBackend.Hubs.PcmHub>("/pcmHub");

// Seed Data
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        await SeedData.Initialize(services);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred seeding the DB.");
    }
}

app.Run();