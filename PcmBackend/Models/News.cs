using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("643_News")]
public class News
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public string Title { get; set; } = string.Empty;
    
    public string Content { get; set; } = string.Empty;
    
    public bool IsPinned { get; set; } = false;
    
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    
    public string? ImageUrl { get; set; }
}
