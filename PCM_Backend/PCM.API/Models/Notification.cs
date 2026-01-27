using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_Notifications")]
public class Notification
{
    [Key]
    public int Id { get; set; }
    
    public int ReceiverId { get; set; }
    
    [Required]
    [MaxLength(500)]
    public string Message { get; set; } = string.Empty;
    
    [MaxLength(50)]
    public string Type { get; set; } = "Info"; // Info/Success/Warning
    
    [MaxLength(500)]
    public string? LinkUrl { get; set; }
    
    public bool IsRead { get; set; } = false;
    
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    
    // Navigation
    [ForeignKey(nameof(ReceiverId))]
    public virtual Member Receiver { get; set; } = null!;
}
