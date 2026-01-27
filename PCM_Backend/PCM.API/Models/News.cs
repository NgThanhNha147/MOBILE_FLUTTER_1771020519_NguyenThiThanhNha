using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_News")]
public class News
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(500)]
    public string Title { get; set; } = string.Empty;
    
    public string Content { get; set; } = string.Empty;
    
    public bool IsPinned { get; set; } = false;
    
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    
    [MaxLength(500)]
    public string? ImageUrl { get; set; }
}
