using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

public enum TransactionCategoryType { Thu, Chi }

[Table("643_TransactionCategories")]
public class TransactionCategory
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public string Name { get; set; } = string.Empty;
    
    public TransactionCategoryType Type { get; set; }
}
