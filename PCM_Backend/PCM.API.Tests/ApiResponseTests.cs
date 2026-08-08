using PCM.API.DTOs;
using Xunit;

namespace PCM.API.Tests;

public class ApiResponseTests
{
    [Fact]
    public void SuccessResponseContainsDataAndUtcTimestamp()
    {
        var response = ApiResponse<int>.SuccessResponse("created", 42);

        Assert.True(response.Success);
        Assert.Equal(42, response.Data);
        Assert.Equal(DateTimeKind.Utc, response.Timestamp.Kind);
    }

    [Fact]
    public void PagedResponseCalculatesNavigationState()
    {
        var response = new PagedResponse<int> { Total = 21, Page = 2, PageSize = 10 };

        Assert.Equal(3, response.TotalPages);
        Assert.True(response.HasNext);
        Assert.True(response.HasPrevious);
    }
}
