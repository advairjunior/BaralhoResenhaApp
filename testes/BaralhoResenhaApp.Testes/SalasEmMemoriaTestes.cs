using Microsoft.Extensions.Time.Testing;
using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

public sealed class SalasEmMemoriaTestes
{
    [Fact]
    public void CodigoAceitaMinusculasEEspacos()
    {
        var salas = new SalasEmMemoria(new Baralho([]));
        var sala = salas.Criar();

        Assert.Same(sala, salas.Obter($" {sala.Codigo.ToLowerInvariant()} "));
        Assert.DoesNotContain('I', sala.Codigo);
        Assert.DoesNotContain('O', sala.Codigo);
    }

    [Fact]
    public void SalaParadaHaMaisDeDozeHorasSome()
    {
        var relogio = new FakeTimeProvider(DateTimeOffset.UtcNow);
        var salas = new SalasEmMemoria(new Baralho([]), relogio);
        var antiga = salas.Criar();
        antiga.Entrar("Ana", false);

        relogio.Advance(SalasEmMemoria.TempoParada + TimeSpan.FromMinutes(1));
        var nova = salas.Criar();

        Assert.Throws<SalaNaoEncontradaException>(() => salas.Obter(antiga.Codigo));
        Assert.Same(nova, salas.Obter(nova.Codigo));
    }
}
