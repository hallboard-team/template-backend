using Microsoft.AspNetCore.Mvc;

namespace {{NAMESPACE}};

[ApiController]
[Route("api/[controller]")]
public class {{NAME}} : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok();
    }
}