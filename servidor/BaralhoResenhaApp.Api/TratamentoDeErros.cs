using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Api;

public sealed class TratamentoDeErros(RequestDelegate proximo)
{
    public async Task InvokeAsync(HttpContext contexto)
    {
        try
        {
            await proximo(contexto);
        }
        catch (SalaNaoEncontradaException excecao)
        {
            await Responder(contexto, StatusCodes.Status404NotFound, excecao.Message);
        }
        catch (JogadorNaoReconhecidoException excecao)
        {
            await Responder(contexto, StatusCodes.Status401Unauthorized, excecao.Message);
        }
        catch (AcaoNaoPermitidaException excecao)
        {
            await Responder(contexto, StatusCodes.Status409Conflict, excecao.Message);
        }
    }

    private static Task Responder(HttpContext contexto, int status, string mensagem)
    {
        contexto.Response.StatusCode = status;
        return contexto.Response.WriteAsJsonAsync(new { mensagem });
    }
}
