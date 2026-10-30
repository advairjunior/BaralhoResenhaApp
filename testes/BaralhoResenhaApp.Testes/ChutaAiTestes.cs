using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// 🎯 Chuta aí: a carta faz uma pergunta com resposta em número, cada um chuta
/// em segredo no celular. Quem chutou mais longe leva ponto; quem chegou mais
/// perto distribui goles; quem acertou na mosca ganha uma carta na manga.
/// </summary>
public sealed class ChutaAiTestes
{
    private static readonly Carta Degraus = new("ch-1", ModoDeJogo.ChutaAi, NivelDaCarta.Leve,
        "Quantos degraus tem a escadaria do Cristo Redentor?", Resposta: 220);

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public int Rodada => Sala.Rodada!.Numero;
        public RodadaVisivel Visao(Jogador jogador) => Sala.Visao(jogador.Token).Rodada!;
        public void Chutar(Jogador jogador, string chute) => Sala.Responder(jogador.Token, Rodada, chute);
    }

    private static Mesa Montar(bool cartasNaManga = true)
    {
        var sala = new Sala("ABCD", new Baralho([Degraus]), new Random(8));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.ChutaAi], ZonaSegura: true,
            Ritmo: RitmoDaBebida.Raiz, CartasNaManga: cartasNaManga));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Theory]
    [InlineData("")]
    [InlineData("muito")]
    [InlineData("12abc")]
    public void ChuteTemQueSerUmNumero(string chute)
    {
        var mesa = Montar();

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Chutar(mesa.Todos[0], chute));
        Assert.Equal("Chute um número.", erro.Message);
    }

    [Theory]
    [InlineData("42,195", "42.195")]
    [InlineData("42.195", "42.195")]
    [InlineData(" 1500 ", "1500")]
    [InlineData("-3", "-3")]
    public void AceitaVirgulaOuPontoNasCasasDecimais(string chute, string guardado)
    {
        var mesa = Montar();

        mesa.Chutar(mesa.Todos[0], chute);

        Assert.Equal(guardado, mesa.Visao(mesa.Todos[0]).MinhaResposta);
    }

    [Fact]
    public void ARespostaCertaEOsChutesSoAparecemNaRevelacao()
    {
        var mesa = Montar();

        foreach (var jogador in mesa.Todos.SkipLast(1)) mesa.Chutar(jogador, "100");

        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        Assert.Null(mesa.Visao(mesa.Todos[^1]).MinhaResposta);
        Assert.Null(mesa.Visao(mesa.Todos[^1]).Revelacao);
    }

    [Fact]
    public void QuemChutouMaisLongeLevaPontoEQuemChegouMaisPertoDistribui()
    {
        var mesa = Montar();
        var (ana, beto, caio, duda) = (mesa.Todos[0], mesa.Todos[1], mesa.Todos[2], mesa.Todos[3]);

        mesa.Chutar(ana, "200");
        mesa.Chutar(beto, "230");
        mesa.Chutar(caio, "100");
        mesa.Chutar(duda, "500");

        var revelacao = mesa.Visao(ana).Revelacao!;
        Assert.Equal(220m, revelacao.RespostaCerta);
        // Do mais perto para o mais longe.
        Assert.Equal([beto.Id, ana.Id, caio.Id, duda.Id], revelacao.Chutes.Select(c => c.JogadorId));
        Assert.Equal([230m, 200m, 100m, 500m], revelacao.Chutes.Select(c => c.Valor));
        Assert.Equal([duda.Id], revelacao.Perderam);
        Assert.Equal([beto.Id], revelacao.Escolhidos);
        Assert.True(revelacao.Elogio);
        Assert.Equal(1, duda.Pontos);
        Assert.Equal(0, beto.Pontos);
        Assert.Contains(mesa.Visao(ana).Pendentes, p => p.JogadorId == beto.Id && p.Motivo == MotivoPendente.Elogio);
    }

    [Fact]
    public void EmpateNaPontaVaiTodoMundoJunto()
    {
        var mesa = Montar();
        var (ana, beto, caio, duda) = (mesa.Todos[0], mesa.Todos[1], mesa.Todos[2], mesa.Todos[3]);

        mesa.Chutar(ana, "210");
        mesa.Chutar(beto, "230");
        mesa.Chutar(caio, "120");
        mesa.Chutar(duda, "320");

        var revelacao = mesa.Visao(ana).Revelacao!;
        Assert.Equal(new[] { caio.Id, duda.Id }.Order(), revelacao.Perderam.Order());
        Assert.Equal(new[] { ana.Id, beto.Id }.Order(), revelacao.Escolhidos.Order());
    }

    [Fact]
    public void TodoMundoChutouIgualNinguemLevaNemDistribui()
    {
        var mesa = Montar();

        foreach (var jogador in mesa.Todos) mesa.Chutar(jogador, "300");

        var revelacao = mesa.Visao(mesa.Todos[0]).Revelacao!;
        Assert.Empty(revelacao.Perderam);
        Assert.Empty(revelacao.Escolhidos);
        Assert.False(revelacao.Elogio);
        Assert.All(mesa.Todos, j => Assert.Equal(0, j.Pontos));
    }

    [Fact]
    public void QuemAcertouNaMoscaGanhaUmaCartaNaManga()
    {
        var mesa = Montar();
        var (ana, beto) = (mesa.Todos[0], mesa.Todos[1]);
        var maoAntes = ana.Mao.Count;

        mesa.Chutar(ana, "220");
        mesa.Chutar(beto, "221");
        mesa.Chutar(mesa.Todos[2], "100");
        mesa.Chutar(mesa.Todos[3], "300");

        Assert.Equal(maoAntes + 1, ana.Mao.Count);
        Assert.Contains(ana.Id, mesa.Sala.Rodada!.Ganharam);
        Assert.DoesNotContain(beto.Id, mesa.Sala.Rodada!.Ganharam);
    }

    [Fact]
    public void QuemCriouASalaRevelaSemEsperarQuemNaoChutou()
    {
        var mesa = Montar();
        mesa.Chutar(mesa.Todos[1], "200");
        mesa.Chutar(mesa.Todos[2], "900");

        mesa.Sala.Revelar(mesa.Todos[0].Token, mesa.Rodada);

        var revelacao = mesa.Visao(mesa.Todos[0]).Revelacao!;
        Assert.Equal(2, revelacao.Chutes.Count);
        Assert.Equal([mesa.Todos[2].Id], revelacao.Perderam);
    }

    [Fact]
    public void BancoTemPerguntasDoChutaAiTodasComResposta()
    {
        var cartas = CatalogoDeCartas.Carregar().Cartas.Where(c => c.Modo == ModoDeJogo.ChutaAi).ToList();

        Assert.True(cartas.Count >= 25, $"só {cartas.Count} cartas");
        Assert.All(cartas, c =>
        {
            Assert.StartsWith("ch-", c.Id);
            Assert.NotNull(c.Resposta);
            Assert.EndsWith("?", c.Texto);
        });
    }
}
