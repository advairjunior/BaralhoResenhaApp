using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Cartas na manga, estilo Uno: cada um guarda até 3 e usa na hora certa
/// sobre o que a carta da mesa fez com ele (ou com outra pessoa).
/// </summary>
public sealed class CartasNaMangaTestes
{
    private static readonly Carta Comum = new("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se usa óculos.");
    private static readonly Carta Dose = new("bs-2", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Conta ou bebe 2.", Goles: 2);
    private static readonly Carta Jokenpo = new("mp-pp", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve,
        "Pedra, papel e tesoura: {jogador} contra {jogador2}.", Duelo: true, Jokenpo: true);

    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Bia, Jogador Caio)
    {
        public int Rodada => Sala.Rodada!.Numero;
        public void Mao(Jogador jogador, params CartaNaManga[] cartas)
        {
            jogador.Mao.Clear();
            jogador.Mao.AddRange(cartas);
        }
    }

    private static Mesa Montar(Carta carta, bool cartasNaManga = true)
    {
        var sala = new Sala("ABCD", new Baralho([carta]), new Random(3));
        var ana = sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", false);
        var caio = sala.Entrar("Caio", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [carta.Modo], true,
            Ritmo: RitmoDaBebida.Raiz, CartasNaManga: cartasNaManga));
        sala.Comecar(ana.Token);
        return new Mesa(sala, ana, bia, caio);
    }

    [Fact]
    public void ACadaNoiteTodoMundoComecaComUmaCarta()
    {
        var ligado = Montar(Comum);
        Assert.All(new[] { ligado.Ana, ligado.Bia, ligado.Caio }, j => Assert.Single(j.Mao));

        var desligado = Montar(Comum, cartasNaManga: false);
        Assert.Empty(desligado.Ana.Mao);
    }

    [Fact]
    public void EscudoCancelaOQueACartaFezComVoce()
    {
        var mesa = Montar(Comum);
        mesa.Mao(mesa.Ana, CartaNaManga.Escudo);
        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);

        mesa.Sala.UsarCarta(mesa.Ana.Token, mesa.Rodada, CartaNaManga.Escudo, null);

        Assert.Equal(0, mesa.Ana.Pontos);
        Assert.Equal(0, mesa.Ana.Goles);
        Assert.Empty(mesa.Ana.Mao);
        Assert.Equal(1, mesa.Ana.Estatisticas.CartasUsadas);
        var uso = Assert.Single(mesa.Sala.Visao(mesa.Bia.Token).Rodada!.Usos);
        Assert.Equal((mesa.Ana.Id, CartaNaManga.Escudo), (uso.Quem, uso.Carta));
    }

    [Fact]
    public void SoUsaCartaQuemTemEQuandoFazSentido()
    {
        var mesa = Montar(Comum);
        mesa.Mao(mesa.Ana, CartaNaManga.Escudo);

        var semConta = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.UsarCarta(mesa.Ana.Token, mesa.Rodada, CartaNaManga.Escudo, null));
        Assert.Equal("A carta não te pegou: guarde a sua para depois.", semConta.Message);

        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);
        var semCarta = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.UsarCarta(mesa.Ana.Token, mesa.Rodada, CartaNaManga.PassaABola, mesa.Bia.Id));
        Assert.Equal("Você não tem essa carta.", semCarta.Message);
    }

    [Fact]
    public void PassaABolaMandaAContaInteiraParaQuemVoceEscolher()
    {
        var mesa = Montar(Dose);
        mesa.Mao(mesa.Ana, CartaNaManga.PassaABola);
        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);
        Assert.Equal(2, mesa.Ana.Goles);

        mesa.Sala.UsarCarta(mesa.Ana.Token, mesa.Rodada, CartaNaManga.PassaABola, mesa.Bia.Id);

        Assert.Equal(0, mesa.Ana.Goles);
        Assert.Equal(2, mesa.Bia.Goles);
        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.UsarCarta(mesa.Bia.Token, mesa.Rodada, CartaNaManga.PassaABola, mesa.Bia.Id));
    }

    [Fact]
    public void BatataQuenteCresceUmGoleACadaPasse()
    {
        var mesa = Montar(Dose);
        mesa.Mao(mesa.Ana, CartaNaManga.BatataQuente);
        mesa.Mao(mesa.Bia, CartaNaManga.BatataQuente);
        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);

        mesa.Sala.UsarCarta(mesa.Ana.Token, mesa.Rodada, CartaNaManga.BatataQuente, mesa.Bia.Id);
        Assert.Equal(0, mesa.Ana.Goles);
        Assert.Equal(3, mesa.Bia.Goles);

        mesa.Sala.UsarCarta(mesa.Bia.Token, mesa.Rodada, CartaNaManga.BatataQuente, mesa.Caio.Id);
        Assert.Equal(0, mesa.Bia.Goles);
        Assert.Equal(4, mesa.Caio.Goles);
    }

    [Fact]
    public void DobraDobraAContaDeOutraPessoa()
    {
        var mesa = Montar(Comum);
        mesa.Mao(mesa.Bia, CartaNaManga.Dobra);

        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.UsarCarta(mesa.Bia.Token, mesa.Rodada, CartaNaManga.Dobra, mesa.Ana.Id));
        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);
        mesa.Sala.UsarCarta(mesa.Bia.Token, mesa.Rodada, CartaNaManga.Dobra, mesa.Ana.Id);

        Assert.Equal(2, mesa.Ana.Pontos);
        Assert.Equal(0, mesa.Bia.Pontos);
    }

    [Fact]
    public void DevolveSoValeNoDueloEVaiParaQuemTeVenceu()
    {
        var comum = Montar(Comum);
        comum.Mao(comum.Ana, CartaNaManga.Devolve);
        comum.Sala.AlternarBebi(comum.Ana.Token, comum.Rodada);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => comum.Sala.UsarCarta(comum.Ana.Token, comum.Rodada, CartaNaManga.Devolve, null));
        Assert.Equal("Devolve só vale no duelo: o ponto volta para quem te venceu.", erro.Message);

        var duelo = Montar(Jokenpo);
        var todos = new[] { duelo.Ana, duelo.Bia, duelo.Caio };
        var primeiro = todos.Single(j => j.Id == duelo.Sala.Rodada!.Duelistas[0]);
        var segundo = todos.Single(j => j.Id == duelo.Sala.Rodada!.Duelistas[1]);
        duelo.Sala.Responder(primeiro.Token, duelo.Rodada, Sala.Tesoura);
        duelo.Sala.Responder(segundo.Token, duelo.Rodada, Sala.Pedra);
        duelo.Mao(primeiro, CartaNaManga.Devolve);

        duelo.Sala.UsarCarta(primeiro.Token, duelo.Rodada, CartaNaManga.Devolve, null);

        Assert.Equal(0, primeiro.Pontos);
        Assert.Equal(1, segundo.Pontos);
    }

    [Fact]
    public void UmaCartaNaMangaPorPessoaACadaCarta()
    {
        var mesa = Montar(Comum);
        mesa.Mao(mesa.Ana, CartaNaManga.Escudo, CartaNaManga.Escudo);
        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);
        mesa.Sala.UsarCarta(mesa.Ana.Token, mesa.Rodada, CartaNaManga.Escudo, null);
        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);
        mesa.Sala.AlternarBebi(mesa.Ana.Token, mesa.Rodada);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.UsarCarta(mesa.Ana.Token, mesa.Rodada, CartaNaManga.Escudo, null));
        Assert.Equal("Uma carta na manga por carta da mesa.", erro.Message);
    }

    [Fact]
    public void QuemVenceODueloGanhaCartaEAMaoTemNoMaximoTres()
    {
        var mesa = Montar(Jokenpo);
        var todos = new[] { mesa.Ana, mesa.Bia, mesa.Caio };
        var primeiro = todos.Single(j => j.Id == mesa.Sala.Rodada!.Duelistas[0]);
        var segundo = todos.Single(j => j.Id == mesa.Sala.Rodada!.Duelistas[1]);
        mesa.Mao(primeiro, CartaNaManga.Escudo);
        mesa.Mao(segundo, CartaNaManga.Escudo, CartaNaManga.Escudo, CartaNaManga.Escudo);

        mesa.Sala.Responder(primeiro.Token, mesa.Rodada, Sala.Papel);
        mesa.Sala.Responder(segundo.Token, mesa.Rodada, Sala.Pedra);

        Assert.Equal(2, primeiro.Mao.Count);
        Assert.Equal([primeiro.Id], mesa.Sala.Visao(mesa.Ana.Token).Rodada!.Ganharam);
        Assert.Equal(3, segundo.Mao.Count);
    }

    [Fact]
    public void CadaUmVeSoAPropriaMaoEDosOutrosSoQuantas()
    {
        var mesa = Montar(Comum);
        mesa.Mao(mesa.Ana, CartaNaManga.Escudo, CartaNaManga.Dobra);
        mesa.Mao(mesa.Bia, CartaNaManga.BatataQuente);

        var visao = mesa.Sala.Visao(mesa.Ana.Token);

        Assert.Equal([CartaNaManga.Escudo, CartaNaManga.Dobra], visao.MinhaMao);
        Assert.Equal(1, visao.Jogadores.Single(j => j.Id == mesa.Bia.Id).CartasNaManga);
    }

    [Fact]
    public void QuemMaisUsaCartaLevaPremio()
    {
        var ana = new Jogador { Id = Guid.NewGuid(), Token = "a", Nome = "Ana" };
        ana.Estatisticas.CartasUsadas = 3;

        var premio = PremiosDaNoite.Calcular([ana]).Single();

        Assert.Equal("Mestre das cartas na manga", premio.Titulo);
        Assert.Equal("Usou 3 cartas na manga", premio.Descricao);
    }
}
